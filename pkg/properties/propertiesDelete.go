/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */

package properties

import (
	"context"
	"net/http"
	"strconv"

	"github.com/galasa.dev/cli/pkg/api"
	galasaErrors "github.com/galasa.dev/cli/pkg/errors"
	"github.com/galasa.dev/cli/pkg/utils"
)

// DeleteProperty - performs all the logic to implement the `galasactl properties delete` command,
// but in a unit-testable manner.
func DeleteProperty(
	namespace string,
	name string,
	apiServerUrl string,
	console utils.Console,
) error {
	var err error

	if err == nil {

		err = deleteCpsProperty(namespace, name, apiServerUrl, console)
		if err == nil {
			console.WriteString("Successfully deleted " + name)
		} else {
			console.WriteString(err.Error())
		}
	}
	return err
}

func deleteCpsProperty(namespace string,
	name string,
	apiServerUrl string,
	console utils.Console,
) error {
	var err error = nil

	var context context.Context = nil

	// An HTTP client which can communicate with the api server in an ecosystem.
	restClient := api.InitialiseAPI(apiServerUrl)

	var httpResponse *http.Response

	apicall := restClient.ConfigurationPropertyStoreAPIApi.DeleteCpsProperty(context, namespace, name)
	_, httpResponse, err = apicall.Execute()

	if err != nil {
		err = galasaErrors.NewGalasaError(galasaErrors.GALASA_ERROR_DELETE_PROPERTY_FAILED, name, err.Error())
	} else {
		if httpResponse.StatusCode != http.StatusOK {
			httpError := "\nhttp response status code: " + strconv.Itoa(httpResponse.StatusCode)
			errString := err.Error() + httpError
			err = galasaErrors.NewGalasaError(galasaErrors.GALASA_ERROR_DELETE_PROPERTY_STATUS_CODE_NOT_OK, errString)
		}
	}

	return err
}
