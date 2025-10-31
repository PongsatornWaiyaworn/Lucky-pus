package controllers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"luckyPus/config"
	"luckyPus/models"
)

func getLotteryCollection() *mongo.Collection {
	return config.Client.Database("luckyPus").Collection("lotteries")
}

func CreateLottery(c *gin.Context) {
	var l models.Lottery
	if err := c.ShouldBindJSON(&l); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uid, _ := primitive.ObjectIDFromHex(userID.(string))
	l.UserID = uid

	if l.Quantity <= 0 {
		l.Quantity = 1
	}

	filter := bson.M{"user_id": uid, "round": l.Round, "number": l.Number}
	var existing models.Lottery
	err := getLotteryCollection().FindOne(context.Background(), filter).Decode(&existing)

	if err == nil {
		update := bson.M{
			"$inc": bson.M{"quantity": l.Quantity},
			"$set": bson.M{"updated_at": time.Now()},
		}
		_, err := getLotteryCollection().UpdateOne(context.Background(), filter, update)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Cannot update lottery quantity"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Lottery quantity updated successfully"})
		return
	}

	l.CreatedAt = time.Now()
	l.UpdatedAt = time.Now()
	l.Status = "ยังไม่ตรวจสอบ"

	result, err := getLotteryCollection().InsertOne(context.Background(), l)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Cannot create lottery"})
		return
	}

	l.ID = result.InsertedID.(primitive.ObjectID)
	c.JSON(http.StatusOK, l)
}

func GetLotteries(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uid, _ := primitive.ObjectIDFromHex(userID.(string))

	cursor, err := getLotteryCollection().Find(context.Background(), bson.M{"user_id": uid})
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
	c.JSON(http.StatusOK, lotteries)
}

func UpdateLottery(c *gin.Context) {
	id := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uid, _ := primitive.ObjectIDFromHex(userID.(string))

	var input struct {
		Round    string `json:"round"`
		Number   string `json:"number"`
		Quantity int    `json:"quantity"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	existsFilter := bson.M{
		"user_id": uid,
		"round":   input.Round,
		"number":  input.Number,
		"_id":     bson.M{"$ne": objID},
	}
	count, _ := getLotteryCollection().CountDocuments(context.Background(), existsFilter)
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Lottery number already exists in this round"})
		return
	}

	quantity := input.Quantity
	if quantity <= 0 {
		quantity = 1
	}

	updateData := bson.M{
		"round":      input.Round,
		"number":     input.Number,
		"quantity":   quantity,
		"updated_at": time.Now(),
	}

	result, err := getLotteryCollection().UpdateOne(
		context.Background(),
		bson.M{"_id": objID, "user_id": uid},
		bson.M{"$set": updateData},
	)
	if err != nil || result.MatchedCount == 0 {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot update lottery or not authorized"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Updated successfully"})
}

func DeleteLottery(c *gin.Context) {
	id := c.Param("id")
	objID, _ := primitive.ObjectIDFromHex(id)

	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uid, _ := primitive.ObjectIDFromHex(userID.(string))

	result, err := getLotteryCollection().DeleteOne(context.Background(), bson.M{"_id": objID, "user_id": uid})
	if err != nil || result.DeletedCount == 0 {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot delete lottery or not authorized"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Deleted"})
}

func AnalyzeUserLottery(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	uid, _ := primitive.ObjectIDFromHex(userID.(string))

	cursor, err := getLotteryCollection().Find(context.Background(), bson.M{"user_id": uid})
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

	if len(lotteries) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"message":       "No lottery data found",
			"total_checked": 0,
			"total_win":     0,
			"win_rate":      0,
			"total_prize":   0,
			"lucky_number":  "NaN",
			"results":       []models.Lottery{},
		})
		return
	}

	type Result struct {
		Number   string `json:"number"`
		Round    string `json:"round"`
		Win      bool   `json:"win"`
		Prize    int    `json:"prize,omitempty"`
		Quantity int    `json:"quantity"`
	}

	var results []Result
	totalWin := 0
	totalPrize := 0
	totalTickets := 0
	numberCount := map[string]int{}

	for _, lot := range lotteries {
		qty := lot.Quantity
		if qty <= 0 {
			qty = 1
		}

		totalTickets += qty

		prize := 0
		win := false

		switch lot.Status {
		case "ถูกรางวัล รางวัลที่ 1":
			prize = 6000000
			win = true
		case "ถูกรางวัล รางวัลข้างเคียงรางวัลที่ 1":
			prize = 100000
			win = true
		case "ถูกรางวัล รางวัลที่ 2":
			prize = 200000
			win = true
		case "ถูกรางวัล รางวัลที่ 3":
			prize = 80000
			win = true
		case "ถูกรางวัล รางวัลที่ 4":
			prize = 40000
			win = true
		case "ถูกรางวัล รางวัลที่ 5":
			prize = 20000
			win = true
		case "ถูกรางวัล รางวัลเลขหน้า 3 ตัว":
			prize = 4000
			win = true
		case "ถูกรางวัล รางวัลเลขท้าย 3 ตัว":
			prize = 4000
			win = true
		case "ถูกรางวัล รางวัลเลขท้าย 2 ตัว":
			prize = 2000
			win = true
		default:
			prize = 0
			win = false
		}

		if win {
			totalWin += qty
			totalPrize += prize * qty
			for _, digit := range lot.Number {
				numberCount[string(digit)] += qty
			}
		}

		results = append(results, Result{
			Number:   lot.Number,
			Round:    lot.Round,
			Win:      win,
			Prize:    prize * qty,
			Quantity: qty,
		})
	}

	luckyNumber := "NaN"
	if totalWin > 0 {
		maxCount := 0
		for num, count := range numberCount {
			if count > maxCount {
				maxCount = count
				luckyNumber = num
			}
		}
	}

	winRate := 0.0
	if totalTickets > 0 {
		winRate = float64(totalWin) / float64(totalTickets) * 100
	}

	c.JSON(http.StatusOK, gin.H{
		"total_checked": totalTickets,
		"total_win":     totalWin,
		"win_rate":      winRate,
		"total_prize":   totalPrize,
		"lucky_number":  luckyNumber,
		"results":       results,
	})
}
