package main

import (
	"log"
	"os"
	"strings"
	"time"

	"luckyPus/config"
	"luckyPus/routes"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	config.LoadEnv()
	config.ConnectDB()

	gin.SetMode(gin.ReleaseMode)

	router := gin.Default()

	corsOrigins := os.Getenv("CORS_ORIGINS")

	allowOrigins := strings.Split(corsOrigins, ",")

	router.Use(cors.New(cors.Config{
		AllowOrigins:  allowOrigins,
		AllowMethods:  []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:  []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders: []string{"Content-Length"},
		MaxAge:        12 * time.Hour,
	}))

	routes.SetupRoutes(router)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("🚀 Server running on port " + port)
	router.Run(":" + port)
}
