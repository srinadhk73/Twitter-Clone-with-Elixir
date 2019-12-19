defmodule ServerTest do
  use ExUnit.Case, async: false
  #use GenServer
  doctest Server
  #doctest Mainmodule

  setup_all do
  {:ok, server_pid} = Task.start(fn()-> Server.start_link() end)
  #Process.sleep(2000)
  #{:ok, server_pid} = Server.start_link()
  #Process.sleep(2000)
  #IO.inspect "Hello"
  #IO.inspect self()
  #:ets.new(:clientsregistry, [:set, :public, :named_table])
  #:ets.new(:mainregistrys, [:set, :public, :named_table])
  :ets.new(:clientsregistry, [:set, :public, :named_table])
  :ets.new(:tweets, [:set, :public, :named_table])
  :ets.new(:hashtags_mentions, [:set, :public, :named_table])
  :ets.new(:subscribedto, [:set, :public, :named_table])
  :ets.new(:followers, [:set, :public, :named_table])
  {:ok, server: server_pid}
  end

  test "register_user 1" do
      Server.handle_cast({:registerUser,"1",self()}, :ok)

      #Process.sleep(500)
      assert_received {:registrationconfirmation}
      #assert_received {:live, "heloo @1"}
  #assert :ets.member(:clientsregistry,"1") == true
      Process.sleep(500)
  end

  test "register_user 2" do
      Server.handle_cast({:registerUser,"2",self()}, :ok)
      Process.sleep(500)
      assert_received {:registrationconfirmation}
      assert :ets.member(:clientsregistry,"2") == true
      Process.sleep(500)
  end


  test  "tweet by 1" do
      Server.handle_cast({:processtweet,"user1 tweeting #COP5615isgreat","1",self()}, :ok)

      Server.handle_cast({:processtweet, "user1 tweeting fghhdg","1",self()}, :ok)
      #Server.handle_cast({:get_my_tweets,"1"}, :ok)

      assert :ets.lookup(:tweets, "1") == [
        {"1",
        [
        "user1 tweeting fghhdg",
        ["user1 tweeting #COP5615isgreat", []]
        ]}
        ]
      Process.sleep(500)

  end

  test "tweet by 2" do
    Server.handle_cast({:processtweet, "heloo @1","2",self()}, :ok)

    assert :ets.lookup(:tweets, "2") == [
      {
        "2",
        [
          "heloo @1", []
        ]
      }
    ]

  end

  test "checking_hashtag_tweets in table" do
      #Process.sleep(500)
      assert :ets.lookup(:hashtags_mentions, "#COP5615isgreat") == [{
         "#COP5615isgreat",
          ["user1 tweeting #COP5615isgreat"]}]
              Process.sleep(500)
  end

  test "user1 queries for hashtag tweets " do
    Server.handle_cast({:tweetsWithHashTag, "#COP5615isgreat","1",self()},:ok)

    assert_received {:repTweetsWithHashtag, ["user1 tweeting #COP5615isgreat"]}

  end

  test "checking_mention_tweets in table" do
      #Process.sleep(500)
      assert :ets.lookup(:hashtags_mentions, "@1") == [{
         "@1",
          ["heloo @1"]}]
              Process.sleep(500)
  end

  test "user1 queries for mentioned tweets" do
      Server.handle_cast({:tweetsWithMention,"1",self()},:ok)
      assert_received {:repTweetsWithMention, ["heloo @1"]}
  end

  test "add_subscriber by user2" do
    Server.handle_cast({:addSubscriber,"1","2"},:ok)
    assert :ets.lookup(:subscribedto,"1") == [{"1", ["2"]}]

  end

  test "add_subscriber by user1" do
    Server.handle_cast({:addSubscriber,"2","1"},:ok)
    assert :ets.lookup(:subscribedto,"2") == [{"2", ["1"]}]

  end

  test "getting_subscribed_tweets_and_retweeting by user1" do
    Server.handle_cast({:tweetSubscribedTo,"1",self()},:ok)
    assert_received {:repTweetsSubscribedTo,["heloo @1",[]]}
    Server.handle_cast({:processtweet,"heloo @1" <> " -RT", "1", self()},:ok)
  end

  test "getting_subscribed_tweets_and_retweeting by user2" do
    Server.handle_cast({:tweetSubscribedTo,"2",self()},:ok)
    assert_received {:repTweetsSubscribedTo,["heloo @1 -RT",["user1 tweeting fghhdg",["user1 tweeting #COP5615isgreat",[]]]]}
    Server.handle_cast({:processtweet,"user1 tweeting fghhdg" <> " -RT", "2", self()},:ok)
  end

  test "user1 asks get_my_tweets" do
      Server.handle_cast({:get_my_tweets,"1",self()},:ok)
      assert_received {:repGetMyTweets,["heloo @1 -RT",["user1 tweeting fghhdg",["user1 tweeting #COP5615isgreat",[]]]]}
  end

  test "user2 asks get_my_tweets" do
      Server.handle_cast({:get_my_tweets,"2",self()},:ok)
      assert_received {:repGetMyTweets,["user1 tweeting fghhdg -RT",["heloo @1",[]]]}
  end

  test "user1 live view" do
    Server.handle_cast({:processtweet, "#DOS","1",self()}, :ok)
    assert_received ({:live,"#DOS"})
  end

  test "user2 live view" do
    Server.handle_cast({:processtweet, "how are you @1","2",self()}, :ok)
    assert_received ({:live,"how are you @1"})
  end

 test "delete 1" do
      Server.handle_cast({:deleteUser, "1"}, :ok)
     assert :ets.lookup(:clientsregistry,"1") == [{"1", nil}]
  end

  test "delete 2" do
       Server.handle_cast({:deleteUser, "2"}, :ok)
      assert :ets.lookup(:clientsregistry,"2") == [{"2", nil}]
   end


end
