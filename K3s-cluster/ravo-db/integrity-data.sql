/* Active DB */
USE ravo_db;
SHOW TABLES;

CREATE TABLE integrity_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255),
    checked_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO integrity_data (data, checked_at) VALUES ('테스트 데이터1', NOW());

SELECT * FROM integrity_data;

/* Standby DB */
USE ravo_db;
SHOW TABLES;

CREATE TABLE integrity_data (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    data VARCHAR(255),
    checked_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO integrity_data (data, checked_at) VALUES ('테스트 데이터1', NOW());

INSERT INTO integrity_data (data, checked_at) VALUES ('테스트 데이터2', NOW());

SELECT * FROM integrity_data;