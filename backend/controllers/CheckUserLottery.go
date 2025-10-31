package controllers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"luckyPus/config"
	"luckyPus/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

func getLotteryCollection__() *mongo.Collection {
	return config.Client.Database("luckyPus").Collection("lotteries")
}

type LottoAPIResponse struct {
	Status   string `json:"status"`
	Response struct {
		Date     string `json:"date"`
		Endpoint string `json:"endpoint"`
		Prizes   []struct {
			ID     string   `json:"id"`
			Name   string   `json:"name"`
			Reward string   `json:"reward"`
			Amount int      `json:"amount"`
			Number []string `json:"number"`
		} `json:"prizes"`
		RunningNumbers []struct {
			ID     string   `json:"id"`
			Name   string   `json:"name"`
			Reward string   `json:"reward"`
			Amount int      `json:"amount"`
			Number []string `json:"number"`
		} `json:"runningNumbers"`
	} `json:"response"`
}

func CheckUserLottery(c *gin.Context) {
	userIDStr, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID, _ := primitive.ObjectIDFromHex(userIDStr.(string))

	now := time.Now()
	var round string
	day := now.Day()
	hour := now.Hour()
	if (day == 1 || day == 16) && hour >= 17 {
		round = fmt.Sprintf("%d/%d/%d", day, now.Month(), now.Year()+543)
	} else {
		if day > 16 {
			round = fmt.Sprintf("16/%d/%d", now.Month(), now.Year()+543)
		} else if day > 1 {
			round = fmt.Sprintf("1/%d/%d", now.Month(), now.Year()+543)
		} else {
			lastMonth := now.AddDate(0, -1, 0)
			round = fmt.Sprintf("16/%d/%d", lastMonth.Month(), lastMonth.Year()+543)
		}
	}

	filter := bson.M{"user_id": userID, "round": round}
	cursor, err := getLotteryCollection__().Find(context.Background(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Cannot get lotteries"})
		return
	}
	defer cursor.Close(context.Background())

	var lotteries []models.Lottery
	if err := cursor.All(context.Background(), &lotteries); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Cannot parse lotteries"})
		return
	}

	resp, err := http.Get("https://lotto.api.rayriffy.com/latest")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Cannot fetch lotto API"})
		return
	}
	defer resp.Body.Close()

	var apiResult LottoAPIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResult); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Cannot decode lotto API result"})
		return
	}

	for i, l := range lotteries {
		status := "ไม่ถูกรางวัล"

		for _, prize := range apiResult.Response.Prizes {
			for _, n := range prize.Number {
				if l.Number == n {
					status = fmt.Sprintf("ถูกรางวัล %s", prize.Name)
				}
			}
		}

		for _, running := range apiResult.Response.RunningNumbers {
			for _, n := range running.Number {
				if running.ID == "runningNumberBackTwo" && len(l.Number) >= 2 && l.Number[len(l.Number)-2:] == n {
					status = fmt.Sprintf("ถูกรางวัล %s", running.Name)
				}
				if (running.ID == "runningNumberBackThree" || running.ID == "runningNumberFrontThree") && len(l.Number) >= 3 {
					if running.ID == "runningNumberBackThree" && l.Number[len(l.Number)-3:] == n {
						status = fmt.Sprintf("ถูกรางวัล %s", running.Name)
					}
					if running.ID == "runningNumberFrontThree" && l.Number[:3] == n {
						status = fmt.Sprintf("ถูกรางวัล %s", running.Name)
					}
				}
			}
		}

		lotteries[i].Status = status
		lotteries[i].UpdatedAt = time.Now()
		_, _ = getLotteryCollection__().UpdateOne(context.Background(),
			bson.M{"_id": l.ID},
			bson.M{"$set": bson.M{"status": status, "updated_at": time.Now()}})
	}

	c.JSON(http.StatusOK, lotteries)
}
