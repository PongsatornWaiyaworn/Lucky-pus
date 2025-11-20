package config

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var S3Client *s3.Client
var S3Bucket string

func LoadS3() {
	S3Bucket = os.Getenv("AWS_BUCKET_NAME")

	creds := aws.NewCredentialsCache(
		credentials.NewStaticCredentialsProvider(
			os.Getenv("AWS_ACCESS_KEY_ID"),
			os.Getenv("AWS_SECRET_ACCESS_KEY"),
			"",
		),
	)

	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(os.Getenv("AWS_REGION")),
		config.WithCredentialsProvider(creds),
	)

	if err != nil {
		log.Fatal("Cannot load AWS config:", err)
	}

	S3Client = s3.NewFromConfig(cfg)
	log.Println("S3 Initialized")
}
