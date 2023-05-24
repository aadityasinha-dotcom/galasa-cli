/*
 * Copyright contributors to the Galasa project
 */
package formatters

import (
	"fmt"
	"strconv"
	"time"

	"github.com/galasa.dev/cli/pkg/galasaapi"
)

// -----------------------------------------------------
// RunsFormatter - implementations can take a collection of run results
// and turn them into a string for display to the user.
const (
	DATE_FORMAT = "2006-01-02 15:04:05"
)

type RunsFormatter interface {
	FormatRuns(runs []galasaapi.Run, apiServerUrl string) (string, error)
	GetName() string

	// IsNeedingDetails - Does this formatter require all of the detailed fields to be filled-in,
	// so they can be displayed ? True if so, false otherwise.
	// The caller may need to make sure such things are gathered before calling, and some
	// formatters may not need all the detail.
	IsNeedingMethodDetails() bool
}

func calculateMaxLengthOfEachColumn(table [][]string) []int {
	columnLengths := make([]int, len(table[0]))
	for _, row := range table {
		for i, val := range row {
			if len(val) > columnLengths[i] {
				columnLengths[i] = len(val)
			}
		}
	}
	return columnLengths
}

func formatTimeReadable(rawTime string) string {
	formattedTimeString := rawTime[0:10] + " " + rawTime[11:19]
	return formattedTimeString
}

func formatTimeForDurationCalculation(rawTime string) time.Time {
	parsedTime, err := time.Parse(time.RFC3339, rawTime)
	if err != nil {
		fmt.Println(err)
	}
	return parsedTime
}

func calculateDurationMilliseconds(start time.Time, end time.Time) string {
	duration := strconv.FormatInt(end.Sub(start).Milliseconds(), 10)

	return duration
}

func getDuration(startTimeStringRaw string, endTimeStringRaw string) string {
	var duration string = ""

	var startTimeStringForDuration time.Time
	var endTimeStringForDuration time.Time

	if len(startTimeStringRaw) > 0 {
		startTimeStringForDuration = formatTimeForDurationCalculation(startTimeStringRaw)
		if len(endTimeStringRaw) > 0 {
			endTimeStringForDuration = formatTimeForDurationCalculation(endTimeStringRaw)
			duration = calculateDurationMilliseconds(startTimeStringForDuration, endTimeStringForDuration)
		}
	}
	return duration
}

func getReadableTime(timeStringRaw string) string {
	var timeStringReadable string = ""
	if len(timeStringRaw) > 0 {
		timeStringReadable = formatTimeReadable(timeStringRaw)
	}
	return timeStringReadable
}