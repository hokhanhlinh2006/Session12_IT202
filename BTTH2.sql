
DROP DATABASE IF EXISTS SocialNetwork;
CREATE DATABASE SocialNetwork;
USE SocialNetwork;


CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- POSTS
CREATE TABLE Posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- COMMENTS
CREATE TABLE Comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- FRIENDS
CREATE TABLE Friends (
    user_id INT,
    friend_id INT,
    status VARCHAR(20),
    CHECK (status IN ('pending','accepted')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (friend_id) REFERENCES Users(user_id)
);

-- LIKES
CREATE TABLE Likes (
    user_id INT,
    post_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (post_id) REFERENCES Posts(post_id)
);

/* =====================================================
   III. SAMPLE DATA
===================================================== */
INSERT INTO Users(username,password,email) VALUES
('an123','123','an@gmail.com'),
('binh','123','binh@gmail.com'),
('linh','123','linh@gmail.com');

INSERT INTO Posts(user_id,content) VALUES
(1,'Learning database systems'),
(1,'My first social post'),
(2,'Hello everyone');

/* =====================================================
   IV. LEVEL: TRUNG BÌNH
===================================================== */

-- VIEW: Public user info
CREATE VIEW vw_public_users AS
SELECT user_id, username, created_at
FROM Users;

-- INDEX: search user
CREATE INDEX idx_users_username ON Users(username);

/* =====================================================
   V. LEVEL: KHÁ
===================================================== */

-- PROCEDURE: create post
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
        SET MESSAGE_TEXT = 'User not found';
    END IF;
END $$

DELIMITER ;

-- VIEW: recent posts (7 days)
CREATE VIEW vw_recent_posts AS
SELECT *
FROM Posts
WHERE created_at >= NOW() - INTERVAL 7 DAY;

-- INDEX optimization
CREATE INDEX idx_posts_user ON Posts(user_id);
CREATE INDEX idx_posts_user_created ON Posts(user_id, created_at);

-- PROCEDURE: count posts
DELIMITER $$

CREATE PROCEDURE sp_count_posts(
    IN p_user_id INT,
    OUT p_total INT
)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM Posts
    WHERE user_id = p_user_id;
END $$

DELIMITER ;

/* =====================================================
   VI. LEVEL: GIỎI
===================================================== */

-- VIEW WITH CHECK OPTION
CREATE VIEW vw_active_users AS
SELECT *
FROM Users
WHERE username IS NOT NULL
WITH CHECK OPTION;

-- PROCEDURE: add friend
DELIMITER $$

CREATE PROCEDURE sp_add_friend(
    IN p_user_id INT,
    IN p_friend_id INT
)
BEGIN
    IF p_user_id = p_friend_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add yourself';
    ELSE
        INSERT INTO Friends(user_id, friend_id, status)
        VALUES (p_user_id, p_friend_id, 'pending');
    END IF;
END $$

DELIMITER ;

-- PROCEDURE: suggest friends
DELIMITER $$

CREATE PROCEDURE sp_suggest_friends(
    IN p_user_id INT,
    INOUT p_limit INT
)
BEGIN
    DECLARE counter INT DEFAULT 0;

    WHILE counter < p_limit DO
        SELECT user_id, username
        FROM Users
        WHERE user_id <> p_user_id
        LIMIT 1;

        SET counter = counter + 1;
    END WHILE;
END $$

DELIMITER ;

-- INDEX + VIEW: top posts
CREATE INDEX idx_likes_post ON Likes(post_id);

CREATE VIEW vw_top_posts AS
SELECT post_id, COUNT(*) AS total_likes
FROM Likes
GROUP BY post_id
ORDER BY total_likes DESC
LIMIT 5;

/* =====================================================
   VII. LEVEL: XUẤT SẮC
===================================================== */

-- PROCEDURE: add comment
DELIMITER $$

CREATE PROCEDURE sp_add_comment(
    IN p_user_id INT,
    IN p_post_id INT,
    IN p_content TEXT
)
BEGIN
    DECLARE u_count INT;
    DECLARE p_count INT;

    SELECT COUNT(*) INTO u_count FROM Users WHERE user_id = p_user_id;
    SELECT COUNT(*) INTO p_count FROM Posts WHERE post_id = p_post_id;

    IF u_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User not exist';
    ELSEIF p_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Post not exist';
    ELSE
        INSERT INTO Comments(user_id, post_id, content)
        VALUES (p_user_id, p_post_id, p_content);
    END IF;
END $$

DELIMITER ;

-- VIEW: post comments
CREATE VIEW vw_post_comments AS
SELECT c.content, u.username, c.created_at
FROM Comments c
JOIN Users u ON c.user_id = u.user_id;

-- PROCEDURE: like post
DELIMITER $$

CREATE PROCEDURE sp_like_post(
    IN p_user_id INT,
    IN p_post_id INT
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM Likes
        WHERE user_id = p_user_id AND post_id = p_post_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Already liked';
    ELSE
        INSERT INTO Likes(user_id, post_id)
        VALUES (p_user_id, p_post_id);
    END IF;
END $$

DELIMITER ;

-- VIEW: post likes
CREATE VIEW vw_post_likes AS
SELECT post_id, COUNT(*) AS total_likes
FROM Likes
GROUP BY post_id;

-- PROCEDURE: search social
DELIMITER $$

CREATE PROCEDURE sp_search_social(
    IN p_option INT,
    IN p_keyword VARCHAR(100)
)
BEGIN
    IF p_option = 1 THEN
        SELECT * FROM Users
        WHERE username LIKE CONCAT('%',p_keyword,'%');
    ELSEIF p_option = 2 THEN
        SELECT * FROM Posts
        WHERE content LIKE CONCAT('%',p_keyword,'%');
    ELSE
        SELECT 'Invalid option' AS message;
    END IF;
END $$

DELIMITER ;

/* =====================================================
   VIII. TEST CALLS
===================================================== */

CALL sp_create_post(1,'Database is important');
CALL sp_count_posts(1,@total_posts);
SELECT @total_posts AS total_posts;

CALL sp_add_friend(1,2);

CALL sp_add_comment(1,1,'Nice post!');
CALL sp_like_post(2,1);

CALL sp_search_social(1,'an');
CALL sp_search_social(2,'database');

SELECT * FROM vw_public_users;
SELECT * FROM vw_recent_posts;
SELECT * FROM vw_post_comments;
SELECT * FROM vw_post_likes;
SELECT * FROM vw_top_posts;
