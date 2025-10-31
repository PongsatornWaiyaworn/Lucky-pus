package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Lottery struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"user_id" json:"user_id"`
	Round     string             `bson:"round" json:"round"` // เช่น "1/10/2025"
	Number    string             `bson:"number" json:"number"`
	Quantity  int                `bson:"quantity" json:"quantity"`
	Status    string             `bson:"status" json:"status"` // "ยังไม่ตรวจสอบ", "ถูกรางวัลที่ ....", "ไม่ถูกรางวัล"
	UpdatedAt time.Time          `bson:"updated_at,omitempty" json:"updated_at,omitempty"`
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}
