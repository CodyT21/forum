# forum

## Project Description ##
This is a basic forum that allow for displaying, creating, editing, and deleting new posts and associated comments. Posts and comments are both stored using a PostgreSQL relational database consisting of 3 tables: posts, comments, and users. Posts contain columns for a unique id, title, content, creation_date, update_date, and author_id. Comments contains columns for a unique id, content, creation_date, update_date, and author_id. Users contain columns for a unique id, unique username, and password which will contained a stored hash of the user password for better data protection. Posts and comments are both ordered by most recent update date, or if not yet been updated, by most recent creation date. A single page will display up to 5 posts or comments, otherwise pagination buttons will show to navigate through the additional post/comment pages. 

User accounts consist of an unique user id, unique username, and a password, stored as a hashed value within the database using the BCrypt hashing function. Editing and deleting of posts and comments are only available if the current logged in user matches the author of the associated post/comment.


## Application Specs ##
  - Ruby Version 2.7.5
  - Tested using Firefox Browser 109.0.1 (64-bit)
  - PostgreSQL version 12.12


## Installing the Application ##
### Setting up the Database ###
Navigate to the project directory. In the terminal, run the command 'psql < ./data/schema.sql'. This will create the database, the tables, and insert the seed data into the database. The seed data consists of 11 forum posts, each with varying numbers of comments from the different users, and 3 users with the following login credentials:
  - User 1
    - username: admin
    - password: password
  - User 2
    - username: test_user
    - password: 12345678
  - User 3
    - username: test_user_2
    - password: password

Seed data was created by performing the actions to create users, posts, comments, and updates within the webapp prior to creating a database dump. Test posts 1 - 3 contain no comments and tests posts 4 - 6 contains comments from multiple different users, however test post 6 contains 6 comments to enable the comment pagination on this post. Test post 7 contains 11 comments to demonstrate the multiple page comment pagination. Test post 8 contains an updated comment to demonstrate the ordering of comments where most recently updated comments are shown before most recently created comments. Test posts 9 and 10 have updated posts to demonstrate the same ordering for posts. Test post 11 contains no comments, but demonstrates the multiple page post pagination.

### Starting the Application ###
Change the current working directory to the project directory and run the 'bundle install' command to install the required Ruby Gems. To start up the application locally, run 'bundle exec ruby forum.rb', then in the browser, enter the url 'localhose:4567/post' to load the app in the browser.

## Steps to Use the Forum App ##
### User Creation and Login/Logout ###
When the starting page is first loaded, the user will be able to view any available post titles, but cannot create a new post, or view the post thread without first logging in using the "Login" button at the bottom of the page. Attempting to perform any of these actions will show a message indicating a signin is required, and the new page will not be displayed.

The login page takes a username and password, or if a user has not yet been created, the "Create New User" button can be used to load the new user creation page. New user creation takes a unique username of between 2 and 50 characters and a password of at least 8 characters in length. Errors will be displayed if a non-unique username, or invalid username/password is entered. Upon successfuly user creation, the login page with a success status message will show, where the user can then enter their login credentials to access all the features of the web app. Invalid username/password combinations will prompt an error message and the user will remain on the login page.

Once a user is logged in, all pages except the user login and creation pages will contain a footer with 2 pieces of information. One is a message indicating the username of the current user that is logged in. The other is a "Logout" button, which when clicked will log out the current user and redirect the user to the starting page that displays the post titles.

### New Post Creation ###
From the starting page, select the "Create New Post" button to load the new post creation page. New posts take a title and content, both of which must be at least 1 character in length. The user_id of the currently logged in user will automatically be included in with the form submission to link the post to the user. This information will then be displayed on the starting page, where the post title, creation date, last update date, and author username will be displayed.

### Editing or Deleting a Post ###
If the currently logged in user has the same user_id as the author_id of a post, next to the post info will be buttons for "Edit" and "Delete". These buttons will only show on posts that share the same author_id as the current user_id. Selecting the "Delete" button will permananetly delete the post from the database and a success message will then show indicating successful deletion of the post. This action will also delete any comments that are linked to this particularly post and they will also be deleted from the database. 

Selecting the "Edit" button will bring up the edit post page. The current values for the title and content will be displayed on the form and the user is able to either edit the content and submit the form, or select the "Cancel" button to return to previous page. If user submits the form without any changes to the content, they will be redirected to the previous page with a status message indicating that the post was not changed and the last updated date and time will not change. If a change is made when the form is submitted, a corresponding status message will show, and the last updated date and time will reflect the new change. The forum inputs for editing a post share the same input requirements as they had when creating a new post.

### New Comment Creation ###
Clicking on the post title will open the page to display the full post with its content and comments. New comments can be added from the form at the bottom of the page. Comments must contain at least 1 character to be valid, otherwise an error message will be displayed and no new comment will be added to the post. Similar to posts, the user_id is automatically included in the form submission. Comments will dislay the comment content, creation date, last update date, and the author username.

### Editing or Deleting a Comment ###
Manipulating existing comments works in much the same way to posts. These buttons will only be availble if the current logged in user has an id that matches the author_id of the comment. Deleting comments will only delete the associated comment, but the original post will be retained.


## Design Limitations
  - Updates to comments are not reflected in the corresponding post's 'Last Updated' date. This field is only updated for posts if the post title or content is changed.
  - User creation is lacking in its implementation. It only offers the ability to create very basic users consisting of a username and a password. No other user information is stored and user login credentials cannot be changed at this time, although implementation would work similar to how post and comment edits are handled.
  - Lack of CSS to improve the look of displaying posts/comments.
