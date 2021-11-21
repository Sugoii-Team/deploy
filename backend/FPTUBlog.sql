CREATE DATABASE FPTUBlog
GO

USE FPTUBlog
GO

CREATE TABLE major
(
    id   UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name NVARCHAR(100) NOT NULL UNIQUE,
)

CREATE TABLE field
(
    id   UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name NVARCHAR(100) NOT NULL UNIQUE,
)

CREATE TABLE category
(
    id       UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name     NVARCHAR(100)    NOT NULL UNIQUE,
    field_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES field (id),
)

CREATE TABLE tag
(
    id   UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name NVARCHAR(100) NOT NULL UNIQUE,
)

CREATE TABLE account_status
(
    id   UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
)

CREATE TABLE account
(
    id                UNIQUEIDENTIFIER          DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    email             VARCHAR(320)     NOT NULL UNIQUE,
    alternative_email VARCHAR(320)     NOT NULL UNIQUE,
    firstname         NVARCHAR(10)     NOT NULL,
    lastname          NVARCHAR(10)     NOT NULL,
    avatar_url        VARCHAR(2084)    NULL,
    description       NVARCHAR(300)    NULL,
    status_id         UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES account_status (id),
    role              VARCHAR(10)      NOT NULL,
    blogs_number      INT              NOT NULL DEFAULT 0,
    avg_rate          FLOAT            NOT NULL DEFAULT 0,
)

CREATE TABLE banned_info
(
    account_id UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES account (id)
        PRIMARY KEY,
    message    NVARCHAR(200)    NOT NULL,
)

CREATE TABLE account_student
(
    id               UNIQUEIDENTIFIER PRIMARY KEY
        FOREIGN KEY REFERENCES account (id),
    school_year      TINYINT          NULL,
    major_id         UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES major (id),
    experience_point INT              NOT NULL DEFAULT 0,
)

CREATE TABLE account_lecturer
(
    id UNIQUEIDENTIFIER PRIMARY KEY
        FOREIGN KEY REFERENCES account (id),
)

CREATE TABLE account_lecturer_field
(
    id          UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    lecturer_id UNIQUEIDENTIFIER FOREIGN KEY REFERENCES account_lecturer (id),
    field_id    UNIQUEIDENTIFIER FOREIGN KEY REFERENCES field (id),
    CONSTRAINT unique_lecturer_id_field_id UNIQUE (lecturer_id, field_id),
)

CREATE TABLE blog_status
(
    id   UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
)

CREATE TABLE rate
(
    id   UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    star INT NOT NULL UNIQUE,
)

CREATE TABLE blog_history
(
    id               UNIQUEIDENTIFIER          DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    author_id        UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES account (id),
    category_id      UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES category (id),
    created_datetime BIGINT           NOT NULL,
    views            INT              NOT NULL DEFAULT 0,
    avg_rate         FLOAT            NOT NULL DEFAULT 0,
)

CREATE TABLE blog
(
    id               UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    thumbnail_url    VARCHAR(2084)    NULL,
    title            NVARCHAR(100)    NOT NULL,
    content          NVARCHAR(max)    NOT NULL,
    description      NVARCHAR(250)    NOT NULL,
    created_datetime BIGINT           NOT NULL,
    status_id        UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES blog_status (id),
    reviewer_id      UNIQUEIDENTIFIER NULL FOREIGN KEY REFERENCES account_lecturer (id),
    review_datetime  BIGINT           NULL,
    blog_history_id  UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES blog_history (id),
)

CREATE TABLE blog_rate
(
    id              UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    blog_history_id UNIQUEIDENTIFIER FOREIGN KEY REFERENCES blog_history (id),
    rate_id         UNIQUEIDENTIFIER FOREIGN KEY REFERENCES rate (id),
    amount          INT,
    CONSTRAINT unique_blog_id_rate_id UNIQUE (blog_history_id, rate_id),
)

CREATE TABLE blog_tag
(
    id      UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    blog_id UNIQUEIDENTIFIER FOREIGN KEY REFERENCES blog (id),
    tag_id  UNIQUEIDENTIFIER FOREIGN KEY REFERENCES tag (id),
    CONSTRAINT unique_blog_id_tag_id UNIQUE (blog_id, tag_id),
)

CREATE TABLE vote
(
    id              UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    account_id      UNIQUEIDENTIFIER FOREIGN KEY REFERENCES account (id),
    blog_history_id UNIQUEIDENTIFIER FOREIGN KEY REFERENCES blog_history (id),
    rate_id         UNIQUEIDENTIFIER FOREIGN KEY REFERENCES rate (id),
    CONSTRAINT unique_account_id_blog_id_rate_id UNIQUE (account_id, blog_history_id),
)

CREATE TABLE award
(
    id       UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    name     NVARCHAR(100) NOT NULL UNIQUE,
    icon_url VARCHAR(2084) NULL,
    point    INT           NOT NULL,
)

CREATE TABLE lecturer_student_award
(
    id          UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()
        PRIMARY KEY,
    lecturer_id UNIQUEIDENTIFIER FOREIGN KEY REFERENCES account_lecturer (id),
    student_id  UNIQUEIDENTIFIER FOREIGN KEY REFERENCES account_student (id),
    award_id    UNIQUEIDENTIFIER FOREIGN KEY REFERENCES award (id),
    datetime    BIGINT NOT NULL,
)

CREATE TABLE admin
(
    username VARCHAR(15) PRIMARY KEY,
    password CHAR(64),
)
GO

CREATE TRIGGER update_blog_avg_rate_after_insert_blog_rate
    ON blog_rate
    AFTER INSERT AS
BEGIN
    DECLARE @blog_history_id UNIQUEIDENTIFIER;

    SELECT @blog_history_id = blog_history_id
    FROM inserted;

    DECLARE @count INT;
    DECLARE @total FLOAT;

    SELECT @count = SUM(amount), @total = SUM(amount * star)
    FROM blog_rate
             INNER JOIN rate on blog_rate.rate_id = rate.id
    WHERE blog_rate.blog_history_id = @blog_history_id;

    IF @count = 0
        UPDATE blog_history
        SET avg_rate = 0
        WHERE id = @blog_history_id;
    ELSE
        UPDATE blog_history
        SET avg_rate = CAST(@total AS FLOAT) / @count
        WHERE id = @blog_history_id;
END
GO

CREATE TRIGGER update_blog_avg_rate_after_update_blog_rate
    ON blog_rate
    AFTER UPDATE AS
BEGIN
    DECLARE @blog_history_id UNIQUEIDENTIFIER;

    SELECT @blog_history_id = blog_history_id
    FROM deleted;

    DECLARE @count INT;
    DECLARE @total FLOAT;

    SELECT @count = SUM(amount), @total = SUM(amount * star)
    FROM blog_rate
             INNER JOIN rate on blog_rate.rate_id = rate.id
    WHERE blog_rate.blog_history_id = @blog_history_id;

    IF @count = 0
        UPDATE blog_history
        SET avg_rate = 0
        WHERE id = @blog_history_id;
    ELSE
        UPDATE blog_history
        SET avg_rate = CAST(@total AS FLOAT) / @count
        WHERE id = @blog_history_id;
END
GO

CREATE TRIGGER update_blog_avg_rate_after_delete_blog_rate
    ON blog_rate
    AFTER DELETE AS
BEGIN
    DECLARE @blog_history_id UNIQUEIDENTIFIER;

    SELECT @blog_history_id = @blog_history_id
    FROM deleted;

    DECLARE @count INT;
    DECLARE @total FLOAT;

    SELECT @count = SUM(amount), @total = SUM(amount * star)
    FROM blog_rate
             INNER JOIN rate on blog_rate.rate_id = rate.id
    WHERE blog_rate.blog_history_id = @blog_history_id;

    IF @count = 0
        UPDATE blog_history
        SET avg_rate = 0
        WHERE id = @blog_history_id;
    ELSE
        UPDATE blog_history
        SET avg_rate = CAST(@total AS FLOAT) / @count
        WHERE id = @blog_history_id;
END
GO

CREATE TRIGGER update_experience_point_after_insert_vote
    ON vote
    AFTER INSERT AS
BEGIN
    DECLARE @blog_history_id UNIQUEIDENTIFIER;
    DECLARE @rate_id UNIQUEIDENTIFIER;

    SELECT @blog_history_id = blog_history_id, @rate_id = rate_id
    FROM inserted;

    DECLARE @star INT;
    SELECT @star = star FROM rate WHERE id = @rate_id;

    IF @star >= 3
        UPDATE account_student
        SET experience_point = experience_point + @star - 2
        WHERE id = (SELECT author_id FROM blog_history WHERE id = @blog_history_id);
END
GO

CREATE TRIGGER update_experience_point_after_delete_vote
    ON vote
    AFTER DELETE AS
BEGIN
    DECLARE @blog_history_id UNIQUEIDENTIFIER;
    DECLARE @rate_id UNIQUEIDENTIFIER;

    SELECT @blog_history_id = blog_history_id, @rate_id = rate_id
    FROM deleted;

    DECLARE @star INT;
    SELECT @star = star FROM rate WHERE id = @rate_id;

    IF @star >= 3
        UPDATE account_student
        SET experience_point = experience_point - @star + 2
        WHERE id = (SELECT author_id FROM blog_history WHERE id = @blog_history_id);
END
GO

CREATE TRIGGER update_experience_point_after_insert_lecturer_student_award
    ON lecturer_student_award
    AFTER INSERT AS
BEGIN
    DECLARE @student_id UNIQUEIDENTIFIER;
    DECLARE @award_id UNIQUEIDENTIFIER;

    SELECT @student_id = student_id, @award_id = award_id
    FROM inserted;

    DECLARE @point INT;
    SELECT @point = point FROM award WHERE id = @award_id;

    UPDATE account_student
    SET experience_point = experience_point + @point
    WHERE id = @student_id;
END
GO

CREATE TRIGGER update_experience_point_after_delete_lecturer_student_award
    ON lecturer_student_award
    AFTER DELETE AS
BEGIN
    DECLARE @student_id UNIQUEIDENTIFIER;
    DECLARE @award_id UNIQUEIDENTIFIER;

    SELECT @student_id = student_id, @award_id = award_id
    FROM deleted;

    DECLARE @point INT;
    SELECT @point = point FROM award WHERE id = @award_id;

    UPDATE account_student
    SET experience_point = experience_point - @point
    WHERE id = @student_id;
END
GO

CREATE TRIGGER update_account_avg_rate_after_update_blog_avg_rate
    ON blog_history
    AFTER UPDATE AS
BEGIN
    DECLARE @author_id UNIQUEIDENTIFIER;

    SELECT @author_id = author_id
    FROM inserted;

    DECLARE @sum_avg_rate_blog FLOAT;
    DECLARE @count INT;

    SELECT @count = COUNT(*), @sum_avg_rate_blog = SUM(avg_rate)
    FROM blog_history
    WHERE author_id = @author_id;

    UPDATE account
    SET avg_rate = @sum_avg_rate_blog / @count
    WHERE id = @author_id;
END
GO
