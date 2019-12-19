defmodule Mainmodule do
    def main(args) do
        :ets.new(:server_node_name,[:set, :public, :named_table])
        {:ok,serverpid}=Task.start fn -> Server.start_link() end
        Process.sleep(1000)

        noOfUsers=args |> Enum.at(0) |> String.to_integer
        noOfTweets=args |> Enum.at(1) |> String.to_integer
	      
	      noOfDelUsers=args |> Enum.at(3) |> String.to_integer
          maxSubsc=args |> Enum.at(2) |> String.to_integer
        :ets.new(:mainregistrys, [:set, :public, :named_table])
        :ets.new(:time_table, [:set, :public, :named_table])

        :ets.insert(:server_node_name,{"Mainprocess",self()})

        serverpid=elem(Enum.at(:ets.lookup(:server_node_name,"Server"),0),1)
       

       
        
       
        task=Task.async(fn->  createUsers(1,noOfUsers,noOfTweets,maxSubsc) end)
        
         Process.sleep(90000)
        tweets_time_diff=0
        queries_subscribedto_time_diff=0
        queries_hashtag_time_diff=0
        queries_mention_time_diff=0
        queries_myTweets_time_diff=0
        statistics(1,noOfUsers,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff)
        #   deletion(noOfUsers,noOfDelUsers,serverpid)
        
        #   receive do: (_ -> :ok)


    end




    def createUsers(count,noOfUsers,noOfTweets,maxSubsc) do
        userName = Integer.to_string(count)
        # noOfTweets = round(Float.floor(maxSubsc/count))
        # noToSubscribe = round(Float.floor(maxSubsc/(noOfUsers-count+1))) - 1
        pid = spawn(fn -> Client.start_link(userName,noOfTweets,maxSubsc,false,noOfUsers) end)
        :ets.insert(:mainregistrys, {userName, pid})
        if (count != noOfUsers) do createUsers(count+1,noOfUsers,noOfTweets,maxSubsc) end
    end


    def statistics(noOfUsers,noOfUsers,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff) do
        # IO.inspect :ets.lookup(:time_table,Integer.to_string(noOfUsers))
        # if :ets.lookup(:time_table,Integer.to_string(noOfUsers)) !=[]do
            [tup]=:ets.lookup(:time_table,Integer.to_string(noOfUsers))
           list= elem(tup,1)
           tweets_time_diff=tweets_time_diff+Enum.at(list,0)
           queries_subscribedto_time_diff=queries_subscribedto_time_diff+Enum.at(list,1)
           queries_hashtag_time_diff=queries_hashtag_time_diff+Enum.at(list,2)
           queries_mention_time_diff= queries_mention_time_diff+Enum.at(list,3)
           queries_myTweets_time_diff=queries_myTweets_time_diff+Enum.at(list,4)
        # end
            
        IO.puts "Avg. time to tweet: #{tweets_time_diff/noOfUsers} milliseconds"
        IO.puts "Avg. time to query tweets subscribe to: #{queries_subscribedto_time_diff/noOfUsers} milliseconds"
        IO.puts "Avg. time to query tweets by hashtag: #{queries_hashtag_time_diff/noOfUsers} milliseconds"
        IO.puts "Avg. time to query tweets by mention: #{queries_mention_time_diff/noOfUsers} milliseconds"
        IO.puts "Avg. time to query all relevant tweets: #{queries_myTweets_time_diff/noOfUsers} milliseconds"
    end

    def statistics(i,noOfUsers,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff) do
        
        # IO.inspect :ets.lookup(:time_table,"1")

    
            # IO.inspect :ets.lookup(:time_table,Integer.to_string(i))
        #    if :ets.lookup(:time_table,Integer.to_string(i)) != [] do
            [tup]=:ets.lookup(:time_table,Integer.to_string(i))
            list= elem(tup,1)
            tweets_time_diff=tweets_time_diff+Enum.at(list,0)
            queries_subscribedto_time_diff=queries_subscribedto_time_diff+Enum.at(list,1)
            queries_hashtag_time_diff=queries_hashtag_time_diff+Enum.at(list,2)
            queries_mention_time_diff= queries_mention_time_diff+Enum.at(list,3)
            queries_myTweets_time_diff=queries_myTweets_time_diff+Enum.at(list,4)
        #    end
            
        statistics(i+1,noOfUsers,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff)
        
    end

    # def converging(0,noOfUsers,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff) do
    #     IO.puts "Avg. time to tweet: #{tweets_time_diff/noOfUsers} milliseconds"
    #     IO.puts "Avg. time to query tweets subscribe to: #{queries_subscribedto_time_diff/noOfUsers} milliseconds"
    #     IO.puts "Avg. time to query tweets by hashtag: #{queries_hashtag_time_diff/noOfUsers} milliseconds"
    #     IO.puts "Avg. time to query tweets by mention: #{queries_mention_time_diff/noOfUsers} milliseconds"
    #     IO.puts "Avg. time to query all relevant tweets: #{queries_myTweets_time_diff/noOfUsers} milliseconds"
    # end

    # def converging(noOfUsers,noOfUsers,tweets_time_diff,queries_subscribedto_time_diff,queries_hashtag_time_diff,queries_mention_time_diff,queries_myTweets_time_diff) do
    #   # Receive convergence messages
    #   receive do
    #     {:statistics,a,b,c,d,e} -> converging(noOfUsers-1,noOfUsers,tweets_time_diff+a,queries_subscribedto_time_diff+b,queries_hashtag_time_diff+c,queries_mention_time_diff+d,queries_myTweets_time_diff+e)
    #   end
    # end


    def deletion(noOfUsers,noOfDelUsers,serverpid) do

        # IO.inspect "--------------------------------------------------------------------------------"
        # Process.sleep(1000)
        deletedList = deleted_list(noOfUsers,noOfDelUsers,0,[],serverpid)
        # Process.sleep(1000)
        Enum.each deletedList, fn userName ->
            pid = spawn(fn ->Client.start_link(userName,-1,-1,true,noOfUsers) end)
            :ets.insert(:mainregistrys, {userName, pid})
        end
        deletion(noOfUsers,noOfDelUsers,serverpid)
    end







def deleted_list(noOfUsers,noOfDelUsers,usersDeleted,deletedList,serverpid) do
  if usersDeleted < noOfDelUsers do
      disconnectClient = :rand.uniform(noOfUsers)
      disconnectClientId = elem(Enum.at(:ets.lookup(:mainregistrys, Integer.to_string(disconnectClient)),0),1)
      if disconnectClientId != nil do
          userName = Integer.to_string(disconnectClient)
          deletedList = [userName | deletedList]
          GenServer.cast(serverpid,{:deleteUser,userName})
          :ets.insert(:mainregistrys, {userName, nil})
          Process.exit(disconnectClientId,:kill)
          IO.puts "Simulator :- User #{userName} has been disconnected"
          deleted_list(noOfUsers,noOfDelUsers,usersDeleted+1,deletedList,serverpid)
      else
          deleted_list(noOfUsers,noOfDelUsers,usersDeleted,deletedList,serverpid)
      end
  else
      deletedList
  end


end

end
