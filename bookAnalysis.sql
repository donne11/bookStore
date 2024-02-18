use library;


-- 1. Which book(s) are Science Fiction books written in the 1960's?
-- List title, author, and year of publication
SELECT title, author, year 
FROM book
WHERE genre_id = 4 AND year BETWEEN 1960 AND 1969;


-- 2. Which users have borrowed no books?
-- Give name and city they live in
-- Write the query in two ways, once by selecting from only one table
-- and using a subquery, and again by joining two tables together.


-- Method using subquery (4 points)
SELECT user_name, city
FROM user
WHERE user_id NOT IN (SELECT user_id FROM borrow);


-- Method using a join (4 points)
SELECT user.user_name, user.city
FROM user
LEFT JOIN borrow ON user.user_id = borrow.user_id
WHERE borrow.user_id IS NULL;


-- 3. How many books were borrowed by each user in each month?
-- Your table should have three columns: user_name, month, num_borrowed
-- You may ignore users that didn't borrow any books and months in which no books were borrowed.
-- Sort by name, then month
-- The month(date) function returns the month number (1,2,3,...12) of a given date. This is adequate for output.
SELECT user_name, month(borrow_dt) month, COUNT(*) AS num_borrowed
FROM user
INNER JOIN borrow ON user.user_id = borrow.user_id
GROUP BY user_name, month
ORDER BY user_name, month;


-- 4. How many times was each book checked out?
-- Output the book's title, genre name, and the number of times it was checked out, and whether the book is still in circulation
-- Include books never borrowed
-- Order from most borrowed to least borrowed
SELECT title, genre_name, COUNT(borrow.book_id) AS num_checked_out, in_circulation
FROM book 
LEFT JOIN borrow ON book.book_id = borrow.book_id
LEFT JOIN genre ON book.genre_id = genre.genre_id
GROUP BY book.book_id, title, genre_name, in_circulation
ORDER BY num_checked_out DESC;


-- 5. How many times did each user return a book late?
-- Include users that never returned a book late or never even borrowed a book
-- Sort by most number of late returns to least number of late returns (regardless of HOW late the returns were.)
SELECT user.user_name, COALESCE(COUNT(late_return.book_id), 0) AS num_late_returns
FROM user
LEFT JOIN (
    SELECT borrow.user_id, borrow.book_id
    FROM borrow
    WHERE borrow.return_dt > borrow.due_dt
) AS late_return ON user.user_id = late_return.user_id
GROUP BY user.user_name
ORDER BY num_late_returns DESC;


-- 6. How many books of each genre where published after 1950?
-- Include genres that are not represented by any book in our catalog
-- as well as genres for which there are books but none published after 1950.
-- Sort output by number of titles in each genre (most to least)
SELECT g.genre_name, COUNT(b.book_id) AS num_books
FROM genre g
LEFT JOIN book b ON g.genre_id = b.genre_id AND b.year >= 1951
GROUP BY g.genre_name
ORDER BY num_books DESC;


-- 7. For each genre, compute a) the number of books borrowed and b) the average
-- number of days borrowed.
-- Includes books never borrowed and genres with no books
-- and in these cases, show zeros instead of null values.
-- Round the averages to one decimal point
-- Sort output in descending order by average
-- Helpful functions: ROUND, IFNULL, DATEDIFF
SELECT g.genre_name, 
       IFNULL(COUNT(borrow.book_id), 0) AS num_borrowed_books,
       ROUND(IFNULL(AVG(DATEDIFF(return_dt, borrow_dt)), 0), 1) AS avg_days_borrowed
       -- find the avergae number of days the books were borrowed
FROM genre g
LEFT JOIN book b ON g.genre_id = b.genre_id
LEFT JOIN borrow ON b.book_id = borrow.book_id
GROUP BY g.genre_name
ORDER BY avg_days_borrowed DESC;


-- 8. List all pairs of books published within 10 years of each other
-- Don't include the book with itself
-- Only list (X,Y) pairs where X was published earlier
-- Output the two titles, and the years they were published, the number of years apart they were published
-- Order pairs from those published closest together to farthest
SELECT b.title AS book1_title, bb.title AS book2_title, 
       b.year AS book1_year, bb.year AS book2_year,
       ABS(b.year - bb.year) AS years_published_apart
FROM book AS b
INNER JOIN book AS bb ON b.book_id < bb.book_id
WHERE ABS(b.year - bb.year) < 11
ORDER BY years_published_apart;


-- 9. Assuming books are returned completely read,
-- Rank the users from fastest to slowest readers (pages per day)
-- include users that borrowed no books (report reading rate as 0.0)
SELECT u.user_name, 
       IFNULL(SUM(b.pages) / DATEDIFF(MAX(borrow.return_dt), MIN(borrow.borrow_dt)), 0.0) AS read_time
       -- determing the time it takes to read by pages and retrun time 
FROM user u
LEFT JOIN borrow ON u.user_id = borrow.user_id
LEFT JOIN book b ON borrow.book_id = b.book_id
GROUP BY u.user_name
ORDER BY read_time DESC;


-- 10. How many books of each genre were checked out by John?
-- Sort descending by number of books checked out in each genre category.
-- Only include genres where at least two books of that genre were checked out.
-- (Count each time the book was checked out even if the same book was checked out
-- by John more than once.)
SELECT g.genre_name, COUNT(b.book_id) AS num_books_checked_out
FROM genre g
INNER JOIN book b ON g.genre_id = b.genre_id
INNER JOIN borrow br ON b.book_id = br.book_id
INNER JOIN user u ON br.user_id = u.user_id
WHERE u.user_name = "John"
GROUP BY g.genre_name
HAVING COUNT(b.book_id) > 1
ORDER BY num_books_checked_out DESC;


-- 11. On average how many books are borrowed per user?
-- Output two averages in one row: one average that includes users that
-- borrowed no books, and one average that excludes users that borrowed no books
SELECT
  AVG(CASE WHEN borrow_count > 0 THEN borrow_count ELSE 0 END) AS average_zero_borrows_include,
  AVG(borrow_count) AS average_zero_borrows_exclude
FROM (
  SELECT user_id, COUNT(*) AS borrow_count
  FROM borrow
  GROUP BY user_id
) AS borrow_counts;


-- 12. How much does each user owe the library. Include users owing nothing
-- Factor in the 10 cents per day fine for late returns and how much they have already paid the library
-- HINTS:
--     The DATEDIFF function takes two dates and counts the number of dates between them
--     The IF function, used in a SELECT clause, might also be helpful.  IF(condition, result_if_true, result_if_false)
--     IF functions can be used inside aggregation functions!
SELECT u.user_name, 
IFNULL(SUM(DATEDIFF(borrow.return_dt, borrow.due_dt) * 0.1) 
- IFNULL(SUM(payment.amount), 0), 0) AS amount_owed -- finding the amount owed
FROM user u
LEFT JOIN borrow ON u.user_id = borrow.user_id
LEFT JOIN payment ON u.user_id = payment.user_id
GROUP BY u.user_name;


-- 13. (4 points) Which books will change your life?
-- Answer: All books.
-- Select all books.
SELECT *
FROM book;

