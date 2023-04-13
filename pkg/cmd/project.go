/*
 * Copyright contributors to the Galasa project
 */
package cmd

import (
	"github.com/spf13/cobra"
)

var (
	projectCmd = &cobra.Command{
		Use:   "project",
		Short: "Manipulate local project source code",
		Long:  "Creates and manipulates Galasa test project source code",
	}
)

func init() {
	RootCmd.AddCommand(projectCmd)
}