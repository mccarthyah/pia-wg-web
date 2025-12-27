package main

import (
	"bytes"
	"html/template"
	"log"
	"net/http"
	"os/exec"
	"strings"
)

type PageData struct {
	Regions []string
	Error   string
}

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/generate", generateHandler)

	log.Println("Listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	regions, err := fetchRegions()
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	tmpl := template.Must(template.ParseFiles("templates/index.html"))
	tmpl.Execute(w, PageData{Regions: regions})
}

func generateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid method", 405)
		return
	}

	user := r.FormValue("username")
	pass := r.FormValue("password")
	region := r.FormValue("region")

	if user == "" || pass == "" || region == "" {
		http.Error(w, "Missing fields", 400)
		return
	}

	cmd := exec.Command(
		"./pia-wg-config",
		"-u", user,
		"-p", pass,
		"-r", region,
	)

	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out

	if err := cmd.Run(); err != nil {
		http.Error(w, out.String(), 500)
		return
	}

	w.Header().Set("Content-Type", "text/plain")
	w.Header().Set("Content-Disposition", "attachment; filename=wg.conf")
	w.Write(out.Bytes())
}

func fetchRegions() ([]string, error) {
	cmd := exec.Command("./pia-wg-config", "-l")
	var out bytes.Buffer
	cmd.Stdout = &out

	if err := cmd.Run(); err != nil {
		return nil, err
	}

	lines := strings.Split(out.String(), "\n")
	var regions []string
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			regions = append(regions, line)
		}
	}
	return regions, nil
}
