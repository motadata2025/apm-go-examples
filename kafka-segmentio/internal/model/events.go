package model

import "time"

type OrderCreated struct {
	OrderID string    `json:"order_id"`
	Amount  float64   `json:"amount"`
	Time    time.Time `json:"time"`
}

type PaymentReceived struct {
	PaymentID string    `json:"payment_id"`
	OrderID   string    `json:"order_id"`
	Amount    float64   `json:"amount"`
	Time      time.Time `json:"time"`
}
