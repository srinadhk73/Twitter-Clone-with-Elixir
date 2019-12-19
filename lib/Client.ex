defmodule Client do
    use GenServer
    require Logger

    def start_link(userName,noOfTweets,noOfSubsc,existing,noOfUsers) do
        GenServer.start_link(__MODULE__, [userName,noOfTweets,noOfSubsc,existing,noOfUsers])
    end


    def init([userName,noOfTweets,noOfSubsc,existing,noOfUsers]) do
        servername=elem(Enum.at(:ets.lookup(:server_node_name,"Server"),0),1)
        if existing do
            IO.puts "User #{userName} :- reconnected"
            loginHandler(userName,servername)
        end

        register(servername,userName)
        
        # IO.inspect "GenServer done"
        receive  do
            {:registrationconfirmation} -> IO.puts("User #{userName}  Registered on Sever")
        end

        userHandler(userName,noOfTweets,noOfSubsc,servername,noOfUsers)
        state=" "
        {:ok,state}
    end

    def register(servername, username) do
      GenServer.cast(servername,{:registerUser,username,self()})
    end

    def loginHandler(userName,servername) do
        IO.inspect "User #{userName} entering loginHandler"
        GenServer.cast(servername,{:loginUser,userName,self()})
        for _<- 1..5 do
            GenServer.cast(servername,{:processtweet,"user #{userName} Tweeting a random number #{randomizer(15)}",userName,:ab})
        end
        liveHandle(userName)
    end

    def userHandler(userName,noOfTweets,noOfSubsc,servername,noOfUsers) do
        # IO.inspect "User #{userName} entering userHandler"
        if noOfSubsc >0 do
            list=zipfSubscribe(noOfUsers)
            susbscList=Enum.at(list,String.to_integer(userName))
             
        end
        start_time = System.system_time(:millisecond)


        # Mention User
        # IO.inspect "User #{userName} Mentionuser process"
        mentionUser=:rand.uniform(String.to_integer(userName))
        GenServer.cast(servername,{:processtweet,"user#{userName} mentioning @#{mentionUser}",userName,:ab})
        # IO.inspect "User #{userName} Mentionuser process done"

        # IO.inspect "User #{userName} HashTag process"
        # HashTag
        GenServer.cast(servername,{:processtweet,"user#{userName} tweeting that #COP5615isgreat",userName,:ab})
        # IO.inspect "User #{userName} Hashtag process done"


        # IO.inspect "User #{userName} Sending tweets process"
        # Send  Tweets
        for _<- 1..noOfTweets do
            GenServer.cast(servername,{:processtweet,"user #{userName} Tweeting a random number #{randomizer(15)}",userName,:ab})
        end
        # IO.inspect "User #{userName} SendinTweets process done"

        # Retweet
        # IO.inspect "User #{userName} Retweet process"
        retweet(userName,servername)
        time_diff=System.system_time(:millisecond) - start_time
        # IO.inspect "User #{userName} RT process done"


         # Handling queries Subscribed to
        start_time = System.system_time(:millisecond)
        GenServer.cast(servername,{:tweetSubscribedTo,userName,:pq})
        # IO.inspect "waiting........"
            receive do
                {:repTweetsSubscribedTo,list} ->  if list != [], do: IO.inspect list, label: "User #{userName} :- Tweets Subscribed To"
            end
        queries_subscribedto_time_diff = System.system_time(:millisecond) - start_time


        #Handling Mentioned Queries
        start_time = System.system_time(:millisecond)
        GenServer.cast(servername,{:tweetsWithMention,userName,:cd})
            receive do
                {:repTweetsWithMention,list} -> IO.inspect list, label: "User #{userName} :- Tweets With @#{userName}"
            end
        queries_mention_time_diff = System.system_time(:millisecond) - start_time

        #Hashtag Query

        start_time = System.system_time(:millisecond)

        # handle_queries_hashtag("#COP5615isgreat",userName)
        tag="#COP5615isgreat"
        GenServer.cast(servername,{:tweetsWithHashTag,tag,userName,:xy})
            receive do
                {:repTweetsWithHashtag,list} -> IO.inspect list, label: "User #{userName} :- Tweets With #{tag}"
            end
        queries_hashtag_time_diff = System.system_time(:millisecond) - start_time


        start_time = System.system_time(:millisecond)
        #Get All Tweets
        # handle_get_my_tweets(userName)
       GenServer.cast(servername,{:get_my_tweets,userName, :on})
            receive do
                {:repGetMyTweets,list} -> IO.inspect list, label: "User #{userName} :- All my tweets"
            end
        queries_myTweets_time_diff = System.system_time(:millisecond) - start_time

        tweets_time_diff = time_diff/(noOfTweets+3)
            timelist=[tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff]
        :ets.insert(:time_table,{userName,timelist})
        # IO.inspect "Times inserted for user #{userName}"
            #Live View
        liveHandle(userName)



    end



    def liveHandle(userName) do
        receive do
            {:live,tweetString} -> IO.inspect tweetString, label:  "User #{userName} :- Live View -----"
        end
        liveHandle(userName)
    end




def randomizer(l) do
    :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
end


def retweet(userName,servername) do
    GenServer.cast(servername,{:tweetSubscribedTo,userName,:pq})
    list = receive do
        {:repTweetsSubscribedTo,list} -> list
    end
    if list != [] do
        rt = hd(list)
      GenServer.cast(servername,{:processtweet,rt <> " -RT",userName,:ab})
    end
end



def generateSubscList(count,noOfSubs,list) do
    if(count == noOfSubs) do
        [count | list]
    else
        generateSubscList(count+1,noOfSubs,[count | list])
    end
end





def zipf_distribute(userName,subscriberList,servername) do
    Enum.each subscriberList, fn subscId ->
        GenServer.cast(servername,{:addSubscriber,userName,Integer.to_string(subscId)})
    end
end




def zipfSubscribe(noOfUsers) do
    usersList=Enum.map(1..noOfUsers,fn(x)-> Integer.to_string(x)end )
    constValue = getZipfValue(length(usersList),1,0)
    constValue = 1/constValue
    # IO.inspect constValue
    constValue = constValue*length(usersList)
    # IO.inspect constValue
    list=Enum.map(1..length(usersList),fn(x)->

      zipfSubs = constValue/x
      x=Integer.to_string(x)
      usersList = usersList -- [x]
      subscribeList = Enum.take_random(usersList, round(zipfSubs))
    end)
    list
  end


  def getZipfValue(len,count,val) when len==count do
    val = val+(1/count)
    val
  end

  def getZipfValue(len,count,val) do
    val = val+(1/count)
    val=getZipfValue(len,count+1,val)
    val
  end



















def randomizer(l) do
    :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
end



    def distribution([head | tail],l) do
        unless Node.alive?() do
            try do
                {ip_tuple,_,_} = head
                current_ip = to_string(:inet_parse.ntoa(ip_tuple))
                if current_ip === "127.0.0.1" do
                    if l > 1 do
                        distribution(tail,l-1)
                    else
                        IO.puts "Could not make current node distributed."
                    end
                else
                    server_node_name = String.to_atom("client@" <> current_ip)
                    Node.start(server_node_name)
                    Node.set_cookie(server_node_name,:monster)
                    Node.connect(String.to_atom("server@" <> current_ip))
                end
            rescue
                _ -> if l > 1, do: distribution(tail,l-1), else: IO.puts "Could not make current node distributed."
            end



        end
    end


end
