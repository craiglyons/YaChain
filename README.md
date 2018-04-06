# Yet Another Blockchain implementation, Elixir/OTP

Clone & connect to 2 nodes in 2 terminals:
```shell
iex --sname foo@localhost -S mix
iex --sname bar@localhost -S mix
```


On the "foo@localhost" node, alias the Controller module for simplicity:
```shell
iex(foo@localhost)1> alias Controller
```

Connect to the "bar" node:
```shell
iex(foo@localhost)2> Node.connect(:"bar@localhost")
true
```

Verify the connection:
```shell
iex(foo@localhost)3> Node.list()
[:bar@localhost]
```

Initialize the chain with a gensis block:
```shell
iex(foo@localhost)4> Controller.insert_genesis_block()
%Yachain.Block{
  index: 0,
  previous_hash: "n/a",
  proof: 100,
  timestamp: #DateTime<2018-04-05 03:21:07.257229Z>,
  transactions: []
}
```

Mine a block, which rewards the miner with a transaction (note the recipient):
```shell
iex(foo@localhost)5> Controller.mine()
%Yachain.Block{
  index: 1,
  previous_hash: "0C2B8AFF43693677D2EB8E4924727A6D9AA40B6796AB53F3E18C67529972284B",
  proof: 35293,
  timestamp: #DateTime<2018-04-05 03:24:17.838591Z>,
  transactions: [
    %Yachain.BlockTransaction{amount: 1, recipient: :foo@localhost, sender: "0"}
  ]
}

```

Inspect the chain, consisting of genesis & mined block:
```shell
iex(foo@localhost)6> Controller.get_chain()
[
  %Yachain.Block{
    index: 0,
    previous_hash: "n/a",
    proof: 100,
    timestamp: #DateTime<2018-04-05 03:24:12.779157Z>,
    transactions: []
  },
  %Yachain.Block{
    index: 1,
    previous_hash: "0C2B8AFF43693677D2EB8E4924727A6D9AA40B6796AB53F3E18C67529972284B",
    proof: 35293,
    timestamp: #DateTime<2018-04-05 03:24:17.838591Z>,
    transactions: [
      %Yachain.BlockTransaction{
        amount: 1,
        recipient: :foo@localhost,
        sender: "0"
      }
    ]
  }
]
```

Push 3 new transactions:\
(The return value '1' is the block that will contain the transaction)
```shell
iex(foo@localhost)7> Controller.new_transaction("Sender1", "Recipient1", 123.00)
1

iex(foo@localhost)8> Controller.new_transaction("Sender2", "Recipient2", 234.00)
1

iex(foo@localhost)9> Controller.new_transaction("Sender3", "Recipient3", 345.00)
1
```

Mine the previous 3 transactions, which cuts a new block:
```shell
iex(foo@localhost)10> Controller.mine()
%Yachain.Block{
  index: 2,
  previous_hash: "24B2488D8E7D84C1F5EC3173601F82CD426343ACC5C2D6C4DCC10C6E0B6280D0",
  proof: 35089,
  timestamp: #DateTime<2018-04-05 03:34:47.616641Z>,
  transactions: [
    %Yachain.BlockTransaction{
      amount: 123.0,
      recipient: "Recipient1",
      sender: "Sender1"
    },
    %Yachain.BlockTransaction{
      amount: 234.0,
      recipient: "Recipient2",
      sender: "Sender2"
    },
    %Yachain.BlockTransaction{
      amount: 345.0,
      recipient: "Recipient3",
      sender: "Sender3"
    },
    %Yachain.BlockTransaction{amount: 1, recipient: :foo@localhost, sender: "0"}
  ]
}
```

Verify the chain with genesis, mined-only block, and 3-transaction mined block:
```shell
iex(foo@localhost)11> Controller.get_chain()
[
  %Yachain.Block{
    index: 0,
    previous_hash: "n/a",
    proof: 100,
    timestamp: #DateTime<2018-04-05 03:24:12.779157Z>,
    transactions: []
  },
  %Yachain.Block{
    index: 1,
    previous_hash: "0C2B8AFF43693677D2EB8E4924727A6D9AA40B6796AB53F3E18C67529972284B",
    proof: 35293,
    timestamp: #DateTime<2018-04-05 03:24:17.838591Z>,
    transactions: [
      %Yachain.BlockTransaction{
        amount: 1,
        recipient: :foo@localhost,
        sender: "0"
      }
    ]
  },
  %Yachain.Block{
    index: 2,
    previous_hash: "24B2488D8E7D84C1F5EC3173601F82CD426343ACC5C2D6C4DCC10C6E0B6280D0",
    proof: 35089,
    timestamp: #DateTime<2018-04-05 03:34:47.616641Z>,
    transactions: [
      %Yachain.BlockTransaction{
        amount: 123.0,
        recipient: "Recipient1",
        sender: "Sender1"
      },
      %Yachain.BlockTransaction{
        amount: 234.0,
        recipient: "Recipient2",
        sender: "Sender2"
      },
      %Yachain.BlockTransaction{
        amount: 345.0,
        recipient: "Recipient3",
        sender: "Sender3"
      },
      %Yachain.BlockTransaction{
        amount: 1,
        recipient: :foo@localhost,
        sender: "0"
      }
    ]
  }
]
```

## Test our length consensus

First, alias the Controller for simplicity on the `bar` node

```
iex(bar@localhost)1> alias Yachain.Controller
Yachain.Controller
```

Insert just the genesis block

```
iex(bar@localhost)2> Controller.insert_genesis_block
%Yachain.Block{
  index: 0,
  previous_hash: "n/a",
  proof: 100,
  timestamp: #DateTime<2018-04-06 01:40:54.967639Z>,
  transactions: []
}
iex(bar@localhost)3>
```

TODO: Update readme w/ consensus demo
