local DecentralizedSGD = require 'dstsgd'
local posix = require 'posix'

local opt = lapp [[
Decentralized SGD testing

   --nodesFile         (default 'nodes.txt')    A text file with all host names and port number
   --weightsFile       (default 'weights.txt')  A text file with weights for parameters from different machines
   --nodeID            (default 0)              Which node is this machine? Set 0 for auto
]]

-- The shared tensor, just for testing
local t = {tensor1 = torch.FloatTensor(1024,1024):fill(opt.nodeID),
           tensor2 = torch.DoubleTensor(256,128):fill(torch.uniform())
          }

-- load nodes and weights from a file
nodes, weights = DecentralizedSGD.LoadConfigFromFile(opt.nodesFile, opt.weightsFile)

-- create decentralized trainer object
dstsgd = DecentralizedSGD.Trainer(nodes, weights, opt.nodeID, t)

print("Start init")
dstsgd.Init()
print("Init done.")
-- create model, etc, while waiting all nodes to connect
dstsgd.StartCommunication()
print("Ready to train!")

for i = 1,10 do
  print("Iteration ", i)
  while true do
    -- compute gradients, etc
    posix.sleep(1)
    print("Computing gradients...")
    -- check the atomic counter to see if we have finished communication
    if dstsgd.CheckIfSyncDone() then
      break
    end
  end
  if i == 10 then
    dstsgd.SetExitFlag()
  end
  print("Averaging...")
  dstsgd.AverageParameters()
  print(t.tensor1[1][1], t.tensor1[1024][1024])
  print(t.tensor2[1][1], t.tensor2[256][128])
end

dstsgd.Terminate()
