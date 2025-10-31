package controllers

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"

	"luckyPus/config"
	"luckyPus/models"
)

var jwtKey []byte

func init() {
	config.LoadEnv()
	config.ConnectDB()

	jwtKey = []byte(config.JWTSecret)
}

func getUserCollection() *mongo.Collection {
	return config.Client.Database("luckyPus").Collection("users")
}

func getDeviceCollection() *mongo.Collection {
	return config.Client.Database("luckyPus").Collection("devices")
}

func generateRandomToken(n int) (string, error) {
	b := make([]byte, n)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func sha256Hex(s string) string {
	h := sha256.Sum256([]byte(s))
	return hex.EncodeToString(h[:])
}

// ====================== Register ======================
func Register(c *gin.Context) {
	var user models.User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	user.Password = string(hash)

	_, err := getUserCollection().InsertOne(context.Background(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้างบัญชีผู้ใช้ได้"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "ลงทะเบียนผู้ใช้สำเร็จ"})
}

// ====================== Login ======================
func Login(c *gin.Context) {
	var input struct {
		Username string `json:"username"`
		Password string `json:"password"`
		DeviceID string `json:"device_id"`
		Name     string `json:"name"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}

	if input.Username != "" && input.Password != "" {
		var user models.User
		err := getUserCollection().FindOne(context.Background(), bson.M{"username": input.Username}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "ไม่พบบัญชีผู้ใช้"})
			return
		}

		err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password))
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "รหัสผ่านไม่ถูกต้อง"})
			return
		}

		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"user_id": user.ID.Hex(),
			"exp":     time.Now().Add(15 * 24 * time.Hour).Unix(),
		})
		accessToken, _ := token.SignedString(jwtKey)

		refreshToken, _ := generateRandomToken(32)
		refreshHash := sha256Hex(refreshToken)

		if input.DeviceID != "" {
			var dev models.Device
			err := getDeviceCollection().FindOne(context.Background(), bson.M{
				"user_id":   user.ID,
				"device_id": input.DeviceID,
			}).Decode(&dev)

			if err != nil {
				dev = models.Device{
					UserID:    user.ID,
					DeviceID:  input.DeviceID,
					Name:      input.Name,
					TokenHash: refreshHash,
					CreatedAt: time.Now(),
				}
				_, _ = getDeviceCollection().InsertOne(context.Background(), dev)
			} else {
				_, _ = getDeviceCollection().UpdateOne(
					context.Background(),
					bson.M{"_id": dev.ID},
					bson.M{"$set": bson.M{"token_hash": refreshHash, "last_used_at": time.Now()}},
				)
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"user_id":       user.ID.Hex(),
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"message":       "เข้าสู่ระบบสำเร็จ",
		})
		return
	}

	if input.DeviceID != "" {
		BiometricLogin(c)
		return
	}

	c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลเข้าสู่ระบบไม่ถูกต้อง"})
}

// ====================== Biometric Login ======================
func BiometricLogin(c *gin.Context) {
	var input struct {
		DeviceID string `json:"device_id" binding:"required"`
		Name     string `json:"name"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}

	var dev models.Device
	err := getDeviceCollection().FindOne(context.Background(), bson.M{"device_id": input.DeviceID}).Decode(&dev)
	if err != nil {
		user := models.User{
			Username: "user_" + input.DeviceID[:6],
			Password: "",
		}
		res, err := getUserCollection().InsertOne(context.Background(), user)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถสร้างบัญชีผู้ใช้ได้"})
			return
		}
		userID := res.InsertedID.(primitive.ObjectID)

		token, _ := generateRandomToken(32)
		dev = models.Device{
			UserID:    userID,
			DeviceID:  input.DeviceID,
			Name:      input.Name,
			TokenHash: sha256Hex(token),
			CreatedAt: time.Now(),
		}
		_, _ = getDeviceCollection().InsertOne(context.Background(), dev)
	}

	jwtToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": dev.UserID.Hex(),
		"exp":     time.Now().Add(15 * 24 * time.Hour).Unix(),
	})
	accessToken, _ := jwtToken.SignedString(jwtKey)

	refreshToken, _ := generateRandomToken(32)
	refreshHash := sha256Hex(refreshToken)

	_, _ = getDeviceCollection().UpdateOne(context.Background(),
		bson.M{"_id": dev.ID},
		bson.M{"$set": bson.M{"token_hash": refreshHash, "last_used_at": time.Now()}},
	)

	c.JSON(http.StatusOK, gin.H{
		"user_id":       dev.UserID.Hex(),
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"message":       "เข้าสู่ระบบด้วยไบโอเมตริกสำเร็จ",
	})
}

// ====================== Device Management ======================
func RegisterDevice(c *gin.Context) {
	var req struct {
		DeviceID     string `json:"device_id" binding:"required"`
		Name         string `json:"name"`
		RefreshToken string `json:"refresh_token" binding:"required"`
		UserID       string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}

	uid, _ := primitive.ObjectIDFromHex(req.UserID)
	hash := sha256Hex(req.RefreshToken)

	dev := models.Device{
		UserID:    uid,
		DeviceID:  req.DeviceID,
		Name:      req.Name,
		TokenHash: hash,
		CreatedAt: time.Now(),
	}
	_, err := getDeviceCollection().InsertOne(context.Background(), dev)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถลงทะเบียนอุปกรณ์ได้"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "ลงทะเบียนอุปกรณ์สำเร็จ"})
}

func RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
		DeviceID     string `json:"device_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}

	hash := sha256Hex(req.RefreshToken)

	var dev models.Device
	err := getDeviceCollection().FindOne(context.Background(), bson.M{
		"device_id":  req.DeviceID,
		"token_hash": hash,
	}).Decode(&dev)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "โทเค็นไม่ถูกต้องหรือหมดอายุ"})
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": dev.UserID.Hex(),
		"exp":     time.Now().Add(15 * 24 * time.Hour).Unix(),
	})
	accessToken, _ := token.SignedString(jwtKey)

	newRefresh, _ := generateRandomToken(32)
	newHash := sha256Hex(newRefresh)
	_, _ = getDeviceCollection().UpdateOne(context.Background(), bson.M{"_id": dev.ID}, bson.M{
		"$set": bson.M{"token_hash": newHash, "last_used_at": time.Now()},
	})

	c.JSON(http.StatusOK, gin.H{
		"access_token":  accessToken,
		"refresh_token": newRefresh,
		"message":       "รีเฟรชโทเค็นสำเร็จ",
	})
}

func RevokeDevice(c *gin.Context) {
	var req struct {
		DeviceID string `json:"device_id" binding:"required"`
		UserID   string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ข้อมูลไม่ถูกต้อง"})
		return
	}
	uid, _ := primitive.ObjectIDFromHex(req.UserID)
	_, err := getDeviceCollection().DeleteOne(context.Background(), bson.M{"user_id": uid, "device_id": req.DeviceID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ไม่สามารถเพิกถอนอุปกรณ์ได้"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "เพิกถอนอุปกรณ์สำเร็จ"})
}
