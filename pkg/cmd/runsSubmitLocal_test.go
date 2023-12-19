/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package cmd

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestRunsSubmitLocalCommandInCommandCollection(t *testing.T) {

	factory := NewMockFactory()
	commands, _ := NewCommandCollection(factory)

	cmd, err := commands.GetCommand(COMMAND_NAME_RUNS_SUBMIT_LOCAL)
	assert.Nil(t, err)
	
	assert.Equal(t, COMMAND_NAME_RUNS_SUBMIT_LOCAL, cmd.Name())
	assert.NotNil(t, cmd.Values())
	assert.IsType(t, &RunsSubmitLocalCmdValues{}, cmd.Values())
	assert.NotNil(t, cmd.CobraCommand())
}


func TestRunsSubmitLocalHelpFlagSetCorrectly(t *testing.T) {
	// Given...
	factory := NewMockFactory()
	
	var args []string = []string{"runs", "submit", "local", "--help"}

	// When...
	err := Execute(factory, args)

	// Then...

	// Check what the user saw is reasonable.
	checkOutput("Displays the options for the 'runs submit local' command.", "", "", factory, t)

	assert.Nil(t, err)
}

func TestRunsSubmitLocalWithoutObrWithClassErrors(t *testing.T) {
	// Given...
	factory := NewMockFactory()
	var args []string = []string{"runs", "submit", "local", "--class", "osgi.bundle/class.path"}

	// When...
	err := Execute(factory, args)

	// Then...
	// Check what the user saw was reasonable
	checkOutput("", "required flag(s) \"obr\" not set", "", factory, t)

	// Should throw an error asking for flags to be set
	assert.NotNil(t, err, "err should have been set!")
	assert.Contains(t, err.Error(), "required flag(s) \"obr\" not set")
}

func TestRunsSubmitLocalWithoutClassWithObrErrors(t *testing.T) {
	// Given...
	factory := NewMockFactory()
	var args []string = []string{"runs", "submit", "local", "--obr", "mvn:second.breakfast/elevenses/0.1.0/brunch"}

	// When...
	err := Execute(factory, args)

	// Then...
	// Check what the user saw was reasonable
	checkOutput("", "required flag(s) \"class\" not set", "", factory, t)

	// Should throw an error asking for flags to be set
	assert.NotNil(t, err, "err should have been set!")
	assert.Contains(t, err.Error(), "required flag(s) \"class\" not set")
}

func TestMultipleRequiredFlagsNotSetReturnsListInError(t *testing.T) {
	// Given...
	factory := NewMockFactory()
	var args []string = []string{"runs", "submit", "local"}

	// When...
	err := Execute(factory, args)

	// Then...
	// Check what the user saw was reasonable
	checkOutput("", "required flag(s) \"class\", \"obr\" not set", "", factory, t)
	
	// Should throw an error asking for flags to be set
	assert.NotNil(t, err, "err should have been set!")
	assert.Contains(t, err.Error(), "required flag(s) \"class\", \"obr\" not set")
}