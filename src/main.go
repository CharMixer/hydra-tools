package main

import (
  "fmt"
  "github.com/spf13/viper"
  "strings"
  "bytes"
  "encoding/base64"
  "encoding/json"
  "io/ioutil"
  "net/http"
  "crypto/tls"
  "math/rand"
)

// input configuration - /in.yml
// output configuration dir - /out

// {"client_id": "'"$CLIENT_ID"'", "client_name": "'"$CLIENT_NAME"'", "client_secret": "'"$CLIENT_SECRET"'", "redirect_uris": ['"$REDIRECT_URIS_JSON"'], "audience": ['"$AUDIENCE_JSON"'], "scope": "'"$SCOPES_JSON"'", "grant_types": ['"$GRANT_TYPES_JSON"'], "response_types": ['"$RESPONSE_TYPES_JSON"']}

type HydraClient struct {
  Id string `json:"client_id"`
  Name string `json:"client_name"`
  Secret string `json:"client_secret"`
  Scopes string `json:"scope"`
  GrantTypes []string `json:"grant_types"`
  Audience []string `json:"audience"`
  ResponseTypes []string `json:"response_types"`
  RedirectUris []string `json:"redirect_uris"`
  TokenEndpointAuthMethod string `json:"token_endpoint_auth_method"`
  PostLogoutRedirectUris string `json:"post_logout_redirect_uris"`
}

type Oauth2Clients struct {
  Rows []struct {
    Client HydraClient
    UpdateIfExists bool
    KeepSecrets bool
    HydraHost string
    ConfigFile string
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

func writeSecretsToFile(hydraClient HydraClient, outputFile string){
  viper.SetConfigFile(outputFile)

  err := viper.ReadInConfig() // Find and read the config file
  if err != nil { // Handle errors reading the config file
    // how to handle this.. We want to continue if no such file
  }

  // should come from config file somehow
  viper.Set("oauth2.client.secret", hydraClient.Secret)
  viper.Set("csrf.authKey", randStringBytesMask(64))
  viper.Set("session.authKey", randStringBytesMask(64))

  viper.WriteConfig()

  fmt.Println("Config file written: " + outputFile)
}

func createSecrets() {
  httpClient := &http.Client{}

  http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

  oauth2Clients := loadOauth2ClientConfig()

  var responseClient HydraClient

  for _, row := range oauth2Clients.Rows {

    responseGet, err := http.Get(row.HydraHost + "/clients/" + row.Client.Id)
    if err != nil {
      fmt.Printf("The HTTP request failed with error %s\n", err)
    } else if responseGet.StatusCode == 404 {
      // client not found, so we should create it

      if row.Client.Secret == "" {
        row.Client.Secret = randStringBytesMask(64)
      }

      jsonPayload, _ := json.Marshal(row.Client)

      request, _ := http.NewRequest("POST", row.HydraHost + "/clients", bytes.NewBuffer(jsonPayload))

      response, _ := httpClient.Do(request)
      responseData, _ := ioutil.ReadAll(response.Body)
      json.Unmarshal(responseData, &responseClient)

      writeSecretsToFile(responseClient, row.ConfigFile)

      fmt.Println(string(responseData))
    } else if responseGet.StatusCode == 200 {
      // client found, we should update it

      if !row.KeepSecrets {
        row.Client.Secret = randStringBytesMask(64)
      }

      jsonPayload, _ := json.Marshal(row.Client)

      request, _ := http.NewRequest("PUT", row.HydraHost + "/clients/" + row.Client.Id , bytes.NewBuffer(jsonPayload))

      response, _ := httpClient.Do(request)
      responseData, _ := ioutil.ReadAll(response.Body)
      json.Unmarshal(responseData, &responseClient)

      if !row.KeepSecrets {
        writeSecretsToFile(responseClient, row.ConfigFile)
      }

      fmt.Println(string(responseData))
    } else {
      // unknown response code, somethings wrong
      panic("Did not get 200 or 404 from " + row.HydraHost + "/clients/" + row.Client.Id)
    }

  }
}

func randStringBytesMask(numberOfBytes int) (string) {
  st := make([]byte, numberOfBytes)
  _, err := rand.Read(st)
  if err != nil {
    return ""
  }
  return base64.StdEncoding.EncodeToString(st)
}

func main() {
  //  viper.WriteConfig()
  //  viper.SafeWriteConfig()

  createSecrets()

}
