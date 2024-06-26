# forum

## Project Description
This is a basic forum that allows for displaying, creating, editing, and deleting new posts and associated comments. Posts and comments are both stored using a PostgreSQL relational database consisting of 3 tables: posts, comments, and users. Posts contain columns for a unique id, title, content, creation_date, update_date, and author_id. Comments contains columns for a unique id, content, creation_date, update_date, author_id, and a corresponding post_id. Users contain columns for a unique id, unique username, and password which will be stored as a hash of the user password for better data protection. Hashing is performed using the BCrypt hashing function. 

Posts and comments are both ordered by most recent update date, or if not yet been updated, by most recent creation date. A single page will display up to 5 posts or comments, otherwise pagination buttons will show to navigate through the additional post/comment pages. Editing and deleting of posts and comments are only available if the current logged in user matches the author of the associated post/comment.

### Design Choices
  - Database creation was left to executing the command manually in the terminal before starting the web app as this is what was done in the RB185 lessons.
  - Only user creation was implemented so that the main collection and their individual objects had the full CRUD operations implementation to align with the project requirements
  - Comments and posts share similar table columns names because they share very similar features. Looking back, it might make more sense to give some of the columns more unique names to help with improving clarity in the sql statements.
  - Updates to comments are not reflected in the corresponding post's 'Last Updated' date. This field is only updated for posts if the post title or content is changed.


## Application Specs
  - Ruby Version 2.7.5
  - Tested using Firefox Browser 109.0.1 (64-bit)
  - PostgreSQL version 12.12


## Installing the Application
### Setting up the Database
Change the current working directory to the project directory and create the database using the command `createdb forum` within the command line interface. Once the database is created, the web app can be started and blank tables will automatically be created. Alternatively, the tables and seed data can be inserted into the database by executing the command `psql -d forum < ./data/seed_data.sql`. A further description of the seed data is below. Seed data can be inserted before or after loading the web app for the first time.

### Starting the Application
Once the database has been set up using the above command, execute the `bundle install` command to install the required Ruby Gems. Then start the WEBrick server by executing the command `bundle exec ruby forum.rb`. Within the browser, enter the url `localhost:4567/posts` to load the app.

#### Seed Data
The seed data consists of 11 forum posts, each with varying numbers of comments from the different users, and 3 users with the following login credentials:
  - User 1
    - username: admin
    - password: password
  - User 2
    - username: test_user
    - password: 12345678
  - User 3
    - username: test_user_2
    - password: password

Seed data was created by performing the actions to create users, posts, comments, and updates within the webapp prior to creating a database dump. Test posts 1 - 3 contain no comments and tests posts 4 - 6 contains comments from multiple different users. Test post 6 contains 6 comments to enable the comment pagination on this post. Test post 7 contains 11 comments to demonstrate the multiple page comment pagination. Test post 8 contains an updated comment to demonstrate the ordering of comments where most recently updated comments are shown before most recently created comments. Test posts 9 and 10 have updated posts to demonstrate the same ordering for posts. Test post 11 contains no comments, but demonstrates the multiple page post pagination.


## How to Use the Forum App
### User Creation and Login/Logout
When the starting page is first loaded, the user will be able to view any available post titles, but cannot create a new post, or view the post thread without first logging in using the "Login" button at the bottom of the page. Attempting to perform any of these actions will show a message indicating a signin is required, and the new page will not be displayed. Manually entering a specific url to a user restricted page will prompt for a login and automatically redirect to the intended page after successful signin.

The login page takes a username and password, or if a user has not yet been created, the "Create New User" button can be used to load the new user creation page. New user creation takes a unique username of between 2 and 50 characters and a password of at least 8 characters in length. Upon valid entries, the user will be redirected to the login page where they can then enter their user's new login credentials.

Once a user is logged in, all pages except the user login and creation pages will contain a footer with 2 pieces of information: a message indicating the current user's username and a logout button.

### New Post Creation
From the starting page, select the "Create New Post" button to load the new post creation page. New posts take a title and content, both of which must be at least 1 character in length. The user_id of the currently logged in user will automatically be included with the form submission to link the post to the user.

### Editing or Deleting a Post
If the currently logged in user has the same user_id as the author_id of a post, next to the post info will be buttons for "Edit" and "Delete". Selecting the "Delete" button will permananetly delete the post from the database and a success message will then show indicating successful deletion of the post. This action will also delete any comments that are linked to this particularly post from the database. 

Selecting the "Edit" button will bring up the edit post page. The current values for the title and content will be displayed on the form and the user is able to either edit the content and submit the form, or select the "Cancel" button to return to previous page. If the user submits the form without any changes to the content, they will be redirected to the previous page with a status message indicating that the post was not changed and the last updated date and time will not change. If a change is made when the form is submitted, a corresponding status message will show, and the last updated date and time will reflect the new change.

### New Comment Creation
Clicking on the post title will open the page to display the full post with its content and comments. New comments can be added from the form at the bottom of the page. Comments must contain at least 1 character to be valid input. Similar to posts, the user_id is automatically included in the form submission.

### Editing or Deleting a Comment
Manipulating existing comments works in much the same way to posts. These buttons will only be availble if the current logged in user has an id that matches the author_id of the comment. Deleting comments will only delete the associated comment, but the original post will be retained.
