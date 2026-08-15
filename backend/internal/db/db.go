// Package db quản lý kết nối PostgreSQL qua GORM, tự migrate schema khi
// khởi động và cung cấp repository truy vấn.
package db

import (
	"context"
	"fmt"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// New mở kết nối GORM tới PostgreSQL bằng DSN đã cấu hình.
func New(ctx context.Context, dsn string) (*gorm.DB, error) {
	gormDB, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn), // chỉ log warning/error + slow query, tránh spam mỗi query
	})
	if err != nil {
		return nil, fmt.Errorf("db: không thể mở kết nối GORM: %w", err)
	}

	sqlDB, err := gormDB.DB()
	if err != nil {
		return nil, fmt.Errorf("db: không lấy được *sql.DB nền: %w", err)
	}
	sqlDB.SetConnMaxLifetime(30 * time.Minute)

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(pingCtx); err != nil {
		return nil, fmt.Errorf("db: không thể kết nối PostgreSQL: %w", err)
	}
	return gormDB, nil
}
