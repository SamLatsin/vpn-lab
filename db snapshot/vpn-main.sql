-- phpMyAdmin SQL Dump
-- version 4.9.5deb2
-- https://www.phpmyadmin.net/
--

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

CREATE TABLE `appstore_notifications` (
  `id` varchar(40) NOT NULL,
  `header` text,
  `payload` text,
  `signature` text,
  `payload_header` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `payload_payload` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `payload_signature` text,
  `renewal_header` text,
  `renewal_payload` text,
  `renewal_signature` text,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `raw` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `cron_jobs` (
  `id` int NOT NULL,
  `name` text,
  `status` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `cron_jobs` (`id`, `name`, `status`) VALUES
(1, 'isCheckingOpenVPNConfigs', 1);

CREATE TABLE `servers` (
  `id` int NOT NULL,
  `name` text,
  `abbreviation` text,
  `premium` tinyint DEFAULT NULL,
  `load` double DEFAULT NULL,
  `type` text,
  `config` text,
  `donor` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `ip` text,
  `lastUpdate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ping` int DEFAULT NULL,
  `synced` tinyint DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `support` (
  `id` int NOT NULL,
  `name` text,
  `email` text,
  `topic` text,
  `text` text,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
  `id` int NOT NULL,
  `email` varchar(320) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `password` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `token` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `isPremium` tinyint NOT NULL DEFAULT '0',
  `subscriptionEndDate` datetime DEFAULT NULL,
  `verificationCode` int DEFAULT NULL,
  `verificationCodeExpiration` datetime DEFAULT NULL,
  `googlePlayPurchaseId` varchar(320) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `appStorePurchaseId` varchar(320) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

ALTER TABLE `appstore_notifications`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `cron_jobs`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `servers`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `support`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_email` (`email`),
  ADD UNIQUE KEY `unique_app_store_purchase_id` (`appStorePurchaseId`),
  ADD UNIQUE KEY `unique_google_play_purchase_id` (`googlePlayPurchaseId`);

ALTER TABLE `cron_jobs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

ALTER TABLE `servers`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1508569;

ALTER TABLE `support`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
