package service

import (
	"context"
	"fmt"

	"callserver/internal/db"
)

type DeviceService struct {
	devices *db.DeviceTokenRepo
}

func NewDeviceService(devices *db.DeviceTokenRepo) *DeviceService {
	return &DeviceService{devices: devices}
}

func (s *DeviceService) RegisterToken(ctx context.Context, userID, platform, pushToken string) error {
	if err := s.devices.RegisterToken(ctx, userID, platform, pushToken); err != nil {
		return fmt.Errorf("device_service: RegisterToken: %w", err)
	}
	return nil
}
