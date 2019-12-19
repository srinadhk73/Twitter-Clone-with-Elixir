defmodule Server do
    use GenServer
    def start_link() do
        GenServer.start_link(__MODULE__,:ok)
    end

    def init(:ok) do
     :ets.insert(:server_node_name,{"Server",self()})
        :ets.new(:clientsregistry, [:set, :public, :named_table])
        :ets.new(:tweets, [:set, :public, :named_table])
        :ets.new(:hashtags_mentions, [:set, :public, :named_table])
        :ets.new(:subscribedto, [:set, :public, :named_table])
        :ets.new(:followers, [:set, :public, :named_table])
        state=""
        {:ok,state}
    end



    def whereis(userName) do
        if :ets.lookup(:clientsregistry, userName) == [] do
            # IO.inspect nil
            nil
        else
            [tup] = :ets.lookup(:clientsregistry, userName)
            # IO.inspect elem(tup,1)
            elem(tup, 1)
        end
    end


    def handle_cast({:registerUser,userName,pid},state) do
        #IO.inspect "In handle cast"
        # IO.inspect pid
        :ets.insert(:clientsregistry, {userName, pid})
        :ets.insert(:tweets, {userName, []})
        :ets.insert(:subscribedto, {userName, []})
        if :ets.lookup(:followers, userName) == [], do: :ets.insert(:followers, {userName, []})
        send(pid,{:registrationconfirmation})
        #IO.inspect "handle cast done"
        {:noreply,state}
    end



    def handle_cast({:deleteUser,userName},state) do
        :ets.insert(:clientsregistry, {userName, nil})
        {:noreply,state}
    end

    def handle_cast({:getTweets,userName},state) do
        elem(Enum.at(:ets.lookup(:tweets,userName),0),1)
        {:noreply,state}
    end

    def handle_cast({:get_my_tweets,userName,var},state) do
        list = elem(Enum.at(:ets.lookup(:tweets,userName),0),1)
        if(var == :on) do
         send(whereis(userName),{:repGetMyTweets,list})
       else
            send(var,{:repGetMyTweets,list})
        end
        {:noreply,state}

    end

    def handle_cast({:getsubscto,userName},state)  do
        elem(Enum.at(:ets.lookup(:subscribedto, userName),0),1)
        {:noreply,state}
    end

    def handle_cast({:getfollowers,userName},state) do
        elem(Enum.at(:ets.lookup(:followers, userName),0),1)
        {:noreply,state}
    end

    def handle_cast({:addSubscriber,userName,subscId},state) do
        addSubscTo(userName,subscId)
        addFollower(subscId,userName)
        {:noreply,state}
    end


    def handle_cast({:tweetsWithMention,userName,var},state) do
        [tup] = if :ets.lookup(:hashtags_mentions, "@" <> userName) != [] do
            :ets.lookup(:hashtags_mentions, "@" <> userName)
        else
            [{"#",[]}]
        end
        list = elem(tup, 1)
        if var == :cd do
        send(whereis(userName),{:repTweetsWithMention,list})
        else
          send(var,{:repTweetsWithMention,list})
        end
        {:noreply,state}
    end

def handle({:tweetsWithHashTag,tag,userName},state) do

    send(whereis(userName), :ping)
  end



def handle_cast({:tweetsWithHashTag,tag,userName,var},state) do
    [tup] = if :ets.lookup(:hashtags_mentions, tag) != [] do
        :ets.lookup(:hashtags_mentions, tag)
    else
        [{"#",[]}]
    end
    list = elem(tup, 1)
    if var == :xy do
    send(whereis(userName),{:repTweetsWithHashtag,list})
    else
      send(var,{:repTweetsWithHashtag,list})
    end
    {:noreply,state}
end

    def handle_cast({:processtweet,tweet,userName,var},state) do
        list=[tweet] ++ [elem(Enum.at(:ets.lookup(:tweets,userName),0),1)]

        :ets.insert(:tweets,{userName,list})
        hashtagsList = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet) |> Enum.concat

        Enum.each hashtagsList, fn hashtag ->
	        [tup] = if :ets.lookup(:hashtags_mentions, hashtag) != [] do
                :ets.lookup(:hashtags_mentions, hashtag)
            else
                [nil]
            end
            if tup == nil do
                :ets.insert(:hashtags_mentions,{hashtag,[tweet]})
            else
                list = elem(tup,1)
                list = [tweet | list]
                :ets.insert(:hashtags_mentions,{hashtag,list})
            end
        end

        mentionsList = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet) |> Enum.concat
        Enum.each mentionsList, fn mention ->
            [tup] = if :ets.lookup(:hashtags_mentions, mention) != [] do
                :ets.lookup(:hashtags_mentions, mention)
            else
                [nil]
            end
            if tup == nil do
                :ets.insert(:hashtags_mentions,{mention,[tweet]})
            else
                list = elem(tup,1)
                list = [tweet | list]
                :ets.insert(:hashtags_mentions,{mention,list})
            end
            userName = String.slice(mention,1, String.length(mention)-1)
            if whereis(userName) != nil do
              if(var == :ab) do
               send(whereis(userName),{:live,tweet})
             else
               send(var,{:live,tweet})
             end
           end
        end

        followersList = elem(Enum.at(:ets.lookup(:followers, userName),0),1)
        Enum.each followersList, fn follower ->
	        if whereis(follower) != nil do
            if(var == :ab) do
             send(whereis(follower),{:live,tweet})
           else
             send(var,{:live,tweet})
           end
           end
        end

        {:noreply,state}
    end

    def handle_cast({:tweetSubscribedTo,userName,var},state)  do
        # IO.inspect "IN handle cast tweetSubscribedTo "
        subscto=elem(Enum.at(:ets.lookup(:subscribedto, userName),0),1)
        list=generate_tweet_list(subscto,[])
        if var == :pq do
        send(whereis(userName),{:repTweetsSubscribedTo,list})
      else
          send(var,{:repTweetsSubscribedTo,list})
      end
        {:noreply,state}
    end

    def generate_tweet_list([head | tail],tweetlist) do
        tweetlist = get_tweets(head) ++ tweetlist
        generate_tweet_list(tail,tweetlist)
    end
    def generate_tweet_list([],tweetlist), do: tweetlist


    def get_tweets(userName) do
        if :ets.lookup(:tweets, userName) == [] do
            []
        else
            [tup] = :ets.lookup(:tweets, userName)
            elem(tup, 1)
        end
    end


    def addSubscTo(userName,subsc)  do
        [tup] = :ets.lookup(:subscribedto, userName)
        list = elem(tup, 1)
        list = [subsc | list]
        :ets.insert(:subscribedto, {userName, list})
    end

    def addFollower(userName,follower) do
        if :ets.lookup(:followers, userName) == [], do: :ets.insert(:followers, {userName, []})
        [tup] = :ets.lookup(:followers, userName)
        list = elem(tup, 1)
        list = [follower | list]
        :ets.insert(:followers, {userName, list})

    end


end
