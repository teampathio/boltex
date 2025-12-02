Mox.defmock(Boltex.MockRepo, for: Boltex.Repo)
Application.put_env(:boltex, :repo, Boltex.MockRepo)
Application.put_env(:tesla, :adapter, Tesla.Mock)

ExUnit.start()
