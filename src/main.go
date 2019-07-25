package main

import (
  "fmt"
  "github.com/spf13/viper"
  "strings"
  "bytes"
  "encoding/json"
  "io/ioutil"
  "net/http"
)

// input configuration - /in.yml
// output configuration dir - /out

type Oauth2Clients struct {
  Clients []struct {
    Id string
    Name string
    Scopes []string
    GrantTypes []string
    Audience []string
    ResponseTypes []string
    RedirectUris []string
    UpdateIfExists bool
    HydraHost string
    OutputFile string
    OutputLines []struct {
      Line string
      Value string
    }
    Verbose bool
  }
}

func init() {
  // lets environment variable override config file
  viper.AutomaticEnv()
  viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
  viper.SetConfigFile("/in.yml")

  err := viper.ReadInConfig() // Find and read the config file
  if err != nil { // Handle errors reading the config file
    panic(fmt.Errorf("Fatal error config file: %s \n", err))
  }
}

func loadOauth2ClientConfig() Oauth2Clients{
  var oauth2Clients Oauth2Clients

  err := viper.Unmarshal(&oauth2Clients)
  if err != nil {
    fmt.Printf("unable to decode into config struct, %v", err)
  }

  return oauth2Clients
}

func createClients() {
  oauth2Clients := loadOauth2ClientConfig()

  fmt.Println("Starting the application...")
  response, err := http.Get("https://httpbin.org/ip")
  if err != nil {
      fmt.Printf("The HTTP request failed with error %s\n", err)
  } else {
      data, _ := ioutil.ReadAll(response.Body)
      fmt.Println(string(data))
  }
  jsonData := map[string]string{"firstname": "Nic", "lastname": "Raboy"}
  jsonValue, _ := json.Marshal(jsonData)
  response, err = http.Post("https://httpbin.org/post", "application/json", bytes.NewBuffer(jsonValue))
  if err != nil {
      fmt.Printf("The HTTP request failed with error %s\n", err)
  } else {
      data, _ := ioutil.ReadAll(response.Body)
      fmt.Println(string(data))
  }
  fmt.Println("Terminating the application...")

  fmt.Println(oauth2Clients)
}

func main() {
  //  viper.WriteConfig()
  //  viper.SafeWriteConfig()

  createClients()

}
