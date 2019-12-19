# TWITTER-CLONE
The goal of this project is to implement a Twitter clone and a client simulator.
The client part(send/receive tweets) and the engine (distribute tweets) are simulated in different processes.

TEAM MEMBERS:

Srinadth Kakkera (0514-0863)
Neharika Khera (8950-0993)

INSTRUCTIONS FOR EXECUTION

The project folder contains:
Main.ex
Server.ex
Client.ex

Client Simulator inputs:

noOfUsers: the number of users to simulate
noOfTweets: the number of tweets a user can make
maxSubsc: the maximum number of subscribers a twitter account can have in the simulation
noOfDelUsers: the percentage of clients to disconnect to simulate periods of live connection and disconnection

Running the project :

1. Go to the project folder
2. build the file using mix escript.build
3. Start the simulator by escript mainmodulex <noOfUsers> <noOfTweets> <maxSubsc> <noOfDelUsers> (Though we explixitly give 4 input arguments, these are generated according to  the requirement irrespective  of provided argument)
4. Note that the simulator do not terminate by itself, it simulates recurring periods of live connection and disconnection
5. To simulate the system with different parameter values, restart the program and repeat the above steps.
6. To run test cases: mix test


Functionalities implemented/Working :

1. Register account
2. Send Tweet: tweets can have hashtags (e.g. #COP5615isgreat) and mentions (@1)
3. Subscribe to user's tweets:
4. Re-tweet: (so that your subscribers get an interesting tweet you got by other means)
5. Querying tweets: querying tweets subscribed to, tweets with specific hashtags, tweets in which the user is mentioned (my mentions)
6. Deliver tweets live: if user is connected, deliver types of tweets live
7. Simulator simulates as many users as possible
8. It simulates periods of live connection and disconnection for users
9. It simulates a Zipf distribution on the number of subscribers. For accounts with lot of subscribers, the number of tweets are increased while making some of the messages retweets.

What is working:

Number of users(max) =2000  
Number of tweets per user(max)=50

Output:

1. On the simulator's console we print query results for all the 3 types of queries, prefixed with the corresponding user's ID.
2. The simulator's console also prints live tweets for every user.
  User ID is prefixed to this output as well to identify which user's live view is getting updated.
3. If <noOfDelUsers> parameter is 0, the clients simulator console displays the performance statistics at the end.
Otherwise, it prints the statistics and continues to simulate periods of live connection and disconnection.

Test cases:

1. register user1
2. register user2
3. tweets send by user1 (includes hashtag tweet)
4. tweet send by user2 (includes mention tweet)
5. checks the hashtag tweets in :hashtag_mention table
6. user1 queries for hashtag tweets
7. checks mention tweets in :hashtag_mention table
8. user1 queries for mentioned tweets
9. user1 subscribed user2, value updated in :addSubscriber table
10. user2 subscribed user1, value updated in :addSubscriber table
11. user1 gets its subscribed and retweets to one of its subscribed tweets
12. user1 gets its subscribed and retweets to one of its subscribed tweets
13. user1 queries for all its tweets
14. user2 queries for all its tweets
15. user1 live views the tweet without querying
16. user2 live views the tweet without querying
17. user1 account is deleted
18. user2 account is deleted
