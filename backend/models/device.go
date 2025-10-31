package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Device struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID     primitive.ObjectID `bson:"user_id" json:"user_id"`
	DeviceID   string             `bson:"device_id" json:"device_id"`
	Name       string             `bson:"name" json:"name"`
	TokenHash  string             `bson:"token_hash" json:"-"`
	CreatedAt  time.Time          `bson:"created_at" json:"created_at"`
	LastUsedAt time.Time          `bson:"last_used_at,omitempty" json:"last_used_at"`
}
