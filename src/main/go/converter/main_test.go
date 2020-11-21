package main

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

const expectedCsv = "street,city,zip,state,beds,baths,sq__ft,type,sale_date,price,latitude,longitude\n3526 HIGH ST,SACRAMENTO,95838,CA,2,1,836,Residential,Wed May 21 00:00:00 EDT 2008,59222,38.631913,-121.434879\n"
const expectedJson = `[{"street":"3526 HIGH ST","city":"SACRAMENTO","zip":95838,"state":"CA","beds":2,"baths":1,"sq__ft":836,"type":"Residential","sale_date":"Wed May 21 00:00:00 EDT 2008","price":59222,"latitude":38.631913,"longitude":-121.434879}]`

const expectedCsvFile = "test/expected.csv"
const expectedJsonFile = "test/expected.json"

func TestJsonToCsv(t *testing.T) {
	in := expectedJson
	out, err := jsonToCsv([]byte(in))
	if err != nil {
		t.Error(err)
	}

	expected := expectedCsv
	if string(out) != expected {
		t.Errorf("jsonToCsv():\nGot: %s\nExpected: %s", string(out), expected)
	}
}

func TestCsvToJson(t *testing.T) {
	in := expectedCsv
	out, err := csvToJson([]byte(in))
	if err != nil {
		t.Error(err)
	}

	expected := expectedJson
	if string(out) != expected {
		t.Errorf("jsonToCsv():\nGot: %s\nExpected: %s", string(out), expected)
	}
}

func TestConvertFile(t *testing.T) {
	pathCsv := expectedCsvFile
	pathJson := expectedJsonFile

	assert.FileExists(t, pathCsv, "Missing test file")
	assert.FileExists(t, pathJson, "Missing test file")

	strEmpty := ""

	// JSON file to CSV stdout
	outputCsv := captureStdout(func() {
		ConvertFile(&pathJson, &strEmpty)
	})
	expectedCsv, err := ioutil.ReadFile(pathCsv)
	if err != nil {
		t.Error(err)
	}
	assert.Equal(t, outputCsv, string(expectedCsv), "JSON file to CSV result mismatch")

	// CSV file to JSON stdout
	outputJson := captureStdout(func() {
		ConvertFile(&pathCsv, &strEmpty)
	})
	expectedJson, err := ioutil.ReadFile(pathJson)
	if err != nil {
		t.Error(err)
	}
	assert.Equal(t, outputJson, string(expectedJson), "CSV file to JSON result mismatch")
}

func captureStdout(f func()) string {
	// Save current Stdout
	stdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	// Capture Stdout of f()
	f()
	_ = w.Close()
	out, _ := ioutil.ReadAll(r)

	// Restore Stdout
	os.Stdout = stdout

	return string(out)
}
