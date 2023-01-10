#!/usr/bin/env bash


# Where is this script executing from ?
BASEDIR=$(dirname "$0");pushd $BASEDIR 2>&1 >> /dev/null ;BASEDIR=$(pwd);popd 2>&1 >> /dev/null
# echo "Running from directory ${BASEDIR}"
export ORIGINAL_DIR=$(pwd)
cd "${BASEDIR}"


#--------------------------------------------------------------------------
#
# Set Colors
#
#--------------------------------------------------------------------------
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

#--------------------------------------------------------------------------
#
# Headers and Logging
#
#--------------------------------------------------------------------------
underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
success() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}

#-----------------------------------------------------------------------------------------                   
# Functions
#-----------------------------------------------------------------------------------------                   
function usage {
    info "Syntax: build-locally.sh [OPTIONS]"
    cat << EOF
Options are:
-c | --clean : Do a clean build. One of the --clean or --delta flags are mandatory.
-d | --delta : Do a delta build. One of the --clean or --delta flags are mandatory.

Environment variables used:
OPENAPI_GENERATOR_CLI_JAR - Optional. The full path to the openapi generator jar.
    By default, the tool will be downloaded if it's not already found in the 'tools' folder.
EOF
}

#--------------------------------------------------------------------------
# 
# Main script logic
#
#--------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------                   
# Process parameters
#-----------------------------------------------------------------------------------------                   
build_type=""

while [ "$1" != "" ]; do
    case $1 in
        -c | --clean )          build_type="clean"
                                ;;
        -d | --delta )          build_type="delta"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     error "Unexpected argument $1"
                                usage
                                exit 1
    esac
    shift
done

if [[ "${build_type}" == "" ]]; then
    error "Need to use either the --clean or --delta parameter."
    usage
    exit 1  
fi


#--------------------------------------------------------------------------
# Check that the ../framework is present.
h2 "Making sure the openapi yaml file is available..."
if [[ ! -e "../framework" ]]; then
    error "../framework is not present. Clone the framework repository."
    info "The openapi.yaml file from the framework repository is needed to generate a go client for the rest API"
    exit 1
fi

if [[ ! -e "../framework/openapi.yaml" ]]; then 
    error "File ../framework/openapi.yaml is not found."
    info "The openapi.yaml file from the framework repository is needed to generate a go client for the rest API"
    exit 1
fi
success "OK"

#--------------------------------------------------------------------------
# Create a temporary folder which is never checked in.
h2 "Making sure the tools folder is present."
mkdir -p tools
rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to ensure the tools folder is present. rc=${rc}" ; exit 1 ; fi
success "OK"

#--------------------------------------------------------------------------
# Download the open api generator tool if we've not got it already.
export OPENAPI_GENERATOR_CLI_VERSION="6.2.0"
export OPENAPI_GENERATOR_CLI_JAR=${BASEDIR}/tools/openapi-generator-cli-${OPENAPI_GENERATOR_CLI_VERSION}.jar
if [[ ! -e ${OPENAPI_GENERATOR_CLI_JAR} ]]; then
    info "The openapi generator tool is not available, so download it."

    which wget 2>&1 > /dev/null
    rc=$?
    if [[ "${rc}" != "0" ]]; then
        info "The wget tool is not available. Install it and try again."
        exit 1
    fi

    export OPENAPI_GENERATOR_CLI_SITE="https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli"
    wget ${OPENAPI_GENERATOR_CLI_SITE}/${OPENAPI_GENERATOR_CLI_VERSION}/openapi-generator-cli-${OPENAPI_GENERATOR_CLI_VERSION}.jar \
    -O ${OPENAPI_GENERATOR_CLI_JAR}
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to download the open api generator tool. rc=${rc}" ; exit 1 ; fi
    success "Downloaded OK"
fi

#--------------------------------------------------------------------------
# Invoke the generator
h2 "Generate the openapi client go code..."
./genapi.sh 2>&1 > tools/generate-log.txt
rc=$? ; if [[ "${rc}" != "0" ]]; then cat tools/generate-log.txt ; error "Failed to generate the code from the yaml file. rc=${rc}" ; exit 1 ; fi
rm -f tools/generate-log.txt
success "Code generation OK"

#--------------------------------------------------------------------------
# Invoke the generator again with different parameters
h2 "Generate the openapi client go code... part II"
./generate.sh 2>&1 > tools/generate-log.txt
rc=$? ; if [[ "${rc}" != "0" ]]; then cat tools/generate-log.txt ; error "Failed to generate II the code from the yaml file. rc=${rc}" ; exit 1 ; fi
rm -f tools/generate-log.txt
success "Code generation part II - OK"

#--------------------------------------------------------------------------
# Invoke unit tests
# - These are executed within the Makefile currently. 
#   No need to expose it here as we call the makefile shortly.

#--------------------------------------------------------------------------
# Build the executables
if [[ "${build_type}" == "clean" ]]; then
    h2 "Cleaning the binaries out..."
    make clean
    rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to build binary executable galasactl programs. rc=${rc}" ; exit 1 ; fi
    success "Binaries cleaned up - OK"
fi

h2 "Building new binaries..."
make all
rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to build binary executable galasactl programs. rc=${rc}" ; exit 1 ; fi
success "New binaries built - OK"

#--------------------------------------------------------------------------
# Invoke the tool to create a sample project.
rm -fr ${BASEDIR}/temp
mkdir -p ${BASEDIR}/temp
cd ${BASEDIR}/temp


raw_os=$(uname -s) # eg: "Darwin"
os=""
case $raw_os in
    Darwin*) 
        os="darwin" 
        ;;
    Windows*)
        os="windows"
        ;;
    Linux*)
        os="linux"
        ;;
    *) 
        error "Failed to recognise which operating system is in use. $raw_os"
        exit 1
esac

architecture=$(uname -m)

galasactl_command="galasactl-${os}-${architecture}"
info "galasactl command is ${galasactl_command}"

# Invoke the galasactl command to create a project.
${BASEDIR}/bin/${galasactl_command} project create --package com.myco.example --obr 
rc=$?
if [[ "${rc}" != "0" ]]; then
    error " Failed to create the galasa test project using galasactl command. rc=${rc}"
    exit 1
fi

# Now build the source it created.
cd com.myco.example
mvn clean test install 
rc=$?
if [[ "${rc}" != "0" ]]; then
    error " Failed to build the generated source code which galasactl created."
    exit 1
fi

# Return to the top folder so we can do other things.
cd ${BASEDIR}

#--------------------------------------------------------------------------
# Build the documentation
generated_docs_folder=${BASEDIR}/docs/generated
h2 "Generating documentation"
info "Documentation will be placed in ${generated_docs_folder}"
mkdir -p ${generated_docs_folder}

# Figure out which type of machine this script is currently running on.
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux)      machine=linux;;
    Darwin)     machine=darwin;;
    *)          error "Unknown machine type ${unameOut}"
                exit 1
esac
architecture="$(uname -m)"

# Call the documentation generator, which builds .md files
info "Using program ${BASEDIR}/bin/gendocs-galasactl-${machine}-${architecture} to generate the documentation..."
${BASEDIR}/bin/gendocs-galasactl-${machine}-${architecture} ${generated_docs_folder}
rc=$? ; if [[ "${rc}" != "0" ]]; then error "Failed to generate documentation. rc=${rc}" ; exit 1 ; fi

# The files have a line "###### Auto generated by cobra at 17/12/2022"
# As we are (currently) checking-in these .md files, we don't want them to show as 
# changed in git (which compares the content, not timestamps).
# So lets remove these lines from all the .md files.
info "Removing lines with date/time in, to limit delta changes in git..."
mkdir -p ${BASEDIR}/build
temp_file="${BASEDIR}/build/temp.md"
for FILE in ${generated_docs_folder}/*; do 
    mv -f ${FILE} ${temp_file}
    cat ${temp_file} | grep -v "###### Auto generated by" > ${FILE}
    rm ${temp_file}
    success "Processed file ${FILE}"
done
success "Documentation generated - OK"

#--------------------------------------------------------------------------
h2 "Use the results.."
info "Binary executable programs are found in the 'bin' folder."
ls bin | grep -v "gendocs"