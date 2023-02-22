package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"flag"
	"fmt"
	"io/ioutil"
	"math/big"
	"os"
	"time"

	"github.com/lestrrat-go/jwx/jwa"
	"github.com/lestrrat-go/jwx/jws"
)

type MAAPolicyTokenPayload struct {
	AttestationPolicy string `json:"AttestationPolicy"`
}

func main() {
	// variables declaration
	var policyFile string
	var keyRSAPEMFile string
	var err error

	// flags declaration using flag package
	flag.StringVar(&policyFile, "p", "", "Specify path to policy")
	flag.StringVar(&keyRSAPEMFile, "k", "", "Specify path to RSA key PEM file [optional]")
	flag.Parse() // after declaring flags we need to call it

	if flag.NArg() != 0 || len(policyFile) == 0 {
		flag.Usage()
		os.Exit(1)
	}

	// Read policy files
	policyBytes, err := ioutil.ReadFile(policyFile)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(string(policyBytes))

	// Generate an RSA key or read existing RSA key
	var privateRSAKey *rsa.PrivateKey
	if keyRSAPEMFile == "" {
		// Generate and export an RSA key
		privateRSAKey, err = rsa.GenerateKey(rand.Reader, 2048)
		if err != nil {
			fmt.Println(err)
			return
		}

		// PEM Encode the RSA Private Key and Export it
		privateRSAKeyBytes, err := x509.MarshalPKCS8PrivateKey(privateRSAKey)
		if err != nil {
			fmt.Println(err)
			return
		}

		var privateRSAKeyBlock = &pem.Block{
			Type:  "PRIVATE KEY",
			Bytes: privateRSAKeyBytes,
		}

		privateRSAKeyFile, err := os.OpenFile("private_key.pem", os.O_WRONLY|os.O_CREATE, 0644)
		if err != nil {
			fmt.Println(err)
			return
		}

		err = pem.Encode(privateRSAKeyFile, privateRSAKeyBlock)
		if err != nil {
			fmt.Println(err)
			return
		}
		privateRSAKeyFile.Close()

		// Generate a self-signed x509 certificate for the public RSA private key
		cert := &x509.Certificate{
			SerialNumber: big.NewInt(1658),
			Subject: pkix.Name{
				Organization:  []string{"Azure Research"},
				Country:       []string{"UK"},
				Province:      []string{"Cambridgeshire"},
				Locality:      []string{"Cambridge"},
				StreetAddress: []string{"An address goes here"},
				PostalCode:    []string{"Postal code goes here"},
			},
			NotBefore:    time.Now(),
			NotAfter:     time.Now().AddDate(10, 0, 0),
			SubjectKeyId: []byte{1, 2, 3, 4, 6},
			KeyUsage:     x509.KeyUsageDigitalSignature,
		}

		certBytes, err := x509.CreateCertificate(rand.Reader, cert, cert, &privateRSAKey.PublicKey, privateRSAKey)
		if err != nil {
			fmt.Println(err)
			return
		}

		// PEM Encode the public key certificate and Export it
		var publicRSAKeyCertBlock = &pem.Block{
			Type:  "CERTIFICATE",
			Bytes: certBytes,
		}

		publicRSAKeyCertFile, err := os.OpenFile("cert.pem", os.O_WRONLY|os.O_CREATE, 0644)
		if err != nil {
			fmt.Println(err)
			return
		}

		err = pem.Encode(publicRSAKeyCertFile, publicRSAKeyCertBlock)
		if err != nil {
			fmt.Println(err)
			return
		}
		publicRSAKeyCertFile.Close()

	} else {
		privateRSAKeyBytes, err := ioutil.ReadFile(keyRSAPEMFile)
		if err != nil {
			fmt.Println(err)
			return
		}

		data, _ := pem.Decode(privateRSAKeyBytes)
		key, err := x509.ParsePKCS8PrivateKey(data.Bytes)
		if err != nil {
			fmt.Println(err)
			return
		}
		privateRSAKey = key.(*rsa.PrivateKey)
	}

	// Create payload for the attestation policy token
	var payload MAAPolicyTokenPayload
	payload.AttestationPolicy = base64.RawURLEncoding.EncodeToString(policyBytes)
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		fmt.Println(err)
		return
	}

	// Add the x509 certificate to the header
	publicRSAKeyCertBytes, err := ioutil.ReadFile("cert.pem")
	if err != nil {
		fmt.Println(err)
		return
	}

	data, _ := pem.Decode(publicRSAKeyCertBytes)
	cert, err := x509.ParseCertificate(data.Bytes)
	if err != nil {
		fmt.Println(err)
		return
	}

	jwsHeaders := jws.NewHeaders()
	var x5c []string
	x5c = append(x5c, base64.StdEncoding.EncodeToString(cert.Raw))
	jwsHeaders.Set(jws.X509CertChainKey, x5c)
	jws, err := jws.Sign(payloadBytes, jwa.RS256, privateRSAKey, jws.WithHeaders(jwsHeaders))
	if err != nil {
		fmt.Println(err)
		return
	}

	policyJWSFile, err := os.OpenFile("policy.jws", os.O_WRONLY|os.O_CREATE, 0644)
	if err != nil {
		fmt.Println(err)
		return
	}

	policyJWSFile.Write(jws)
	policyJWSFile.Close()
}
