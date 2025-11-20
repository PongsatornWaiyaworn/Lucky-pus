package routes

import (
	"luckyPus/controllers"
	"luckyPus/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(router *gin.Engine) {
	auth := router.Group("/auth")
	{
		auth.POST("/refresh", controllers.RefreshToken)
		auth.POST("/device/register", controllers.RegisterDevice)
		auth.POST("/device/revoke", controllers.RevokeDevice)
		auth.POST("/register", controllers.Register)
		auth.POST("/login", controllers.Login)
	}

	lottery := router.Group("/lottery")
	lottery.Use(middleware.AuthMiddleware())
	{
		lottery.POST("/", controllers.CreateLottery)
		lottery.GET("/", controllers.GetLotteries)
		lottery.PUT("/:id", controllers.UpdateLottery)
		lottery.DELETE("/:id", controllers.DeleteLottery)
		lottery.GET("/check", controllers.CheckUserLottery)
		lottery.GET("/analyze", controllers.AnalyzeUserLottery)
		lottery.GET("/predict", controllers.PredictNextLottery)
		lottery.POST("/upload-image", controllers.UploadLotteryImage)
		lottery.DELETE("/delete-image/:id", controllers.DeleteLotteryImage)
	}
}
