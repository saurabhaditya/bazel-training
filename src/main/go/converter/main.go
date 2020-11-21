package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"github.com/gocarina/gocsv"
)

type Property struct {
	Street    string  `csv:"street" json:"street"`
	City      string  `csv:"city" json:"city"`
	Zip       int     `csv:"zip" json:"zip"`
	State     string  `csv:"state" json:"state"`
	Beds      int     `csv:"beds" json:"beds"`
	Baths     int     `csv:"baths" json:"baths"`
	SqFt      int     `csv:"sq__ft" json:"sq__ft"`
	Type      string  `csv:"type" json:"type"`
	SaleDate  string  `csv:"sale_date" json:"sale_date"`
	Price     int     `csv:"price" json:"price"`
	Latitude  float64 `csv:"latitude" json:"latitude"`
	Longitude float64 `csv:"longitude" json:"longitude"`
}

type fnConvert func([]byte) ([]byte, error)

func main() {

	pathInput := flag.String("in", "", "File to convert (required, either .csv or .json)")
	pathOutput := flag.String("out", "", "File to converted (optional)")
	flag.Parse()

	if *pathInput == "" {
		flag.Usage()
		os.Exit(1)
	}

	if !isFile(pathInput) {
		log.Fatalf("Input file not found: %s\n", *pathInput)
	}

	ConvertFile(pathInput, pathOutput)
}

func csvToJson(dataInput []byte) ([]byte, error) {
	var items []*Property

	if err := gocsv.UnmarshalBytes(dataInput, &items); err != nil {
		return nil, err
	}

	data, err := json.Marshal(&items)
	if err != nil {
		return nil, err
	}

	return data, nil
}

func jsonToCsv(dataInput []byte) ([]byte, error) {
	var items []*Property

	if err := json.Unmarshal(dataInput, &items); err != nil {
		return nil, err
	}

	data, err := gocsv.MarshalBytes(&items)
	if err != nil {
		return nil, err
	}

	return data, nil
}

func ConvertFile(pathInput *string, pathOutput *string) {
	extension := filepath.Ext(*pathInput)
	if extension == ".json" {
		if err := convertFile(*pathInput, *pathOutput, jsonToCsv); err != nil {
			log.Fatal(err)
		}
	} else if extension == ".csv" {
		if err := convertFile(*pathInput, *pathOutput, csvToJson); err != nil {
			log.Fatal(err)
		}
	} else {
		log.Fatalf("Unsupported file type: %s", extension)
	}
}

func convertFile(pathIn string, pathOut string, fn fnConvert) error {
	fileIn, err := os.Open(pathIn)
	if err != nil {
		return fmt.Errorf("could not read file: %s", pathIn)
	}
	//noinspection GoUnhandledErrorResult
	defer fileIn.Close()

	var fileOut *os.File
	if pathOut != "" {
		out, err := os.Create(pathOut)
		if err != nil {
			return fmt.Errorf("could not create output file: %s", pathOut)
		}
		fileOut = out
		//noinspection GoUnhandledErrorResult
		defer fileOut.Close()
	} else {
		fileOut = os.Stdout
	}

	dataInput, err := ioutil.ReadAll(fileIn)
	if err != nil {
		return err
	}

	dataOutput, err := fn(dataInput)
	if err != nil {
		return err
	}

	_, err = fileOut.Write(dataOutput)
	if err != nil {
		return err
	}

	return nil
}

func isFile(filePath *string) bool {
	info, err := os.Stat(*filePath)
	if err != nil {
		return false
	}
	if info.IsDir() {
		return false
	}
	return true
}
