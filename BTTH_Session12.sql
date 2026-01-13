CREATE DATABASE SocialNetwork;
USE SocialNetwork;
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT,
    user_id INT,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
CREATE TABLE Friends (
    user_id INT,
    friend_id INT,
    status VARCHAR(20),
    CHECK (status IN ('pending','accepted')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (friend_id) REFERENCES Users(user_id)
);
CREATE TABLE Likes (
    user_id INT,
    post_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (post_id) REFERENCES Posts(post_id)
);
INSERT INTO Users(username,password,email)
VALUES ('an123','123456','an@gmail.com');
SELECT * FROM Users;
CREATE VIEW vw_public_users AS
SELECT user_id, username, created_at
FROM Users;
SELECT * FROM vw_public_users;
SELECT * FROM Users;
CREATE INDEX idx_users_username ON Users(username);
SELECT * FROM Users WHERE username = 'an123';
DELIMITER $$

CREATE PROCEDURE sp_create_post(
    IN p_user_id INT,
    IN p_content TEXT
)
BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
        INSERT INTO Posts(user_id, content)
        VALUES (p_user_id, p_content);
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User does not exist';
    END IF;
END $$

DELIMITER ;
CALL sp_create_post(1,'Bài viết đầu tiên');
CREATE VIEW vw_recent_posts AS
SELECT *
FROM Posts
WHERE created_at >= NOW() - INTERVAL 7 DAY;
SELECT * FROM vw_recent_posts ORDER BY created_at DESC;
