package config

import (
	"context"
	"log"
	"os"
	"sync"
	"time"

	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	Client    *mongo.Client
	mongoOnce sync.Once
	MongoURI  string
	JWTSecret string
)

func LoadEnv() {
	_ = godotenv.Load()

	MongoURI = os.Getenv("MONGO_URI")
	if MongoURI == "" {
		log.Fatal("MONGO_URI is not set in .env")
	}

	JWTSecret = os.Getenv("JWT_SECRET")
	if JWTSecret == "" {
		log.Fatal("JWT_SECRET is not set in .env")
	}
}

func ConnectDB() *mongo.Client {
	mongoOnce.Do(func() {
		clientOptions := options.Client().ApplyURI(MongoURI)
		ctx, cancel := context.WithTimeout(context.Background(), 1000*time.Second)
		defer cancel()

		client, err := mongo.Connect(ctx, clientOptions)
		if err != nil {
			log.Fatal(err)
		}

		err = client.Ping(ctx, nil)
		if err != nil {
			log.Fatal(err)
		}

		Client = client
		log.Println("Connected to MongoDB!")
	})
	return Client
}
