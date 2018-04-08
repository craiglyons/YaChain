# Yet Another Blockchain implementation
Elixir/OTP

## Capabilities
- Initialize a chain with a genesis block
- Add transactions
- Mine blocks of 1+ transactions w/ proof of work
- Receive a reward for mining in the form of a transaction
- Verify validity of a chain with block hashes
- Resolve conflicting chains across multiple nodes (longest wins)

## Limitations
- Conflict resolution is done manually
- Chains are not automatically distributed

## Usage
Clone & connect to 2 nodes in 2 terminals:
```shell
iex --sname foo@localhost -S mix
iex --sname bar@localhost -S mix
```

### Node `foo`

alias the Controller module for simplicity:
```shell
iex(foo@localhost)1> alias Yachain.Controller
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
  timestamp: #DateTime<2018-04-08 02:16:14.055494Z>,
  transactions: []
}
```

Mine a block, which rewards the miner with a transaction (note the recipient):
```shell
iex(foo@localhost)5> Controller.mine()
%Yachain.Block{
  index: 1,
  previous_hash: "C32F3106A2A617A2EB299394AF3DF33F4E3FD9560E5A94F8974F7090E6310812",
  proof: 35293,
  timestamp: #DateTime<2018-04-08 02:16:37.142731Z>,
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
    timestamp: #DateTime<2018-04-08 02:16:14.055494Z>,
    transactions: []
  },
  %Yachain.Block{
    index: 1,
    previous_hash: "C32F3106A2A617A2EB299394AF3DF33F4E3FD9560E5A94F8974F7090E6310812",
    proof: 35293,
    timestamp: #DateTime<2018-04-08 02:16:37.142731Z>,
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
  previous_hash: "95E4EC328CF24C0C96D070FE1FA48A2E52D7E8D4E379858E56649B36785A7202",
  proof: 35089,
  timestamp: #DateTime<2018-04-08 02:18:21.077158Z>,
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
    timestamp: #DateTime<2018-04-08 02:16:14.055494Z>,
    transactions: []
  },
  %Yachain.Block{
    index: 1,
    previous_hash: "C32F3106A2A617A2EB299394AF3DF33F4E3FD9560E5A94F8974F7090E6310812",
    proof: 35293,
    timestamp: #DateTime<2018-04-08 02:16:37.142731Z>,
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
    previous_hash: "95E4EC328CF24C0C96D070FE1FA48A2E52D7E8D4E379858E56649B36785A7202",
    proof: 35089,
    timestamp: #DateTime<2018-04-08 02:18:21.077158Z>,
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

## Test "consensus"

First, alias the Controller for simplicity on the `bar` node

### Node `bar`
```
iex(bar@localhost)1> alias Yachain.Controller
Yachain.Controller
```

Insert just the genesis block

```
iex(bar@localhost)2> Controller.insert_genesis_block()
%Yachain.Block{
  index: 0,
  previous_hash: "n/a",
  proof: 100,
  timestamp: #DateTime<2018-04-06 01:40:54.967639Z>,
  transactions: []
}
iex(bar@localhost)3>
```
Resolve conflicts, resulting in replacement of `bar`'s shorter chain

```
iex(bar@localhost)3> Controller.resolve_conflicts()
*** Consensus loss, replacing current chain ***
[
  %Yachain.Block{
    index: 0,
    previous_hash: "n/a",
    proof: 100,
    timestamp: #DateTime<2018-04-08 02:16:14.055494Z>,
    transactions: []
  },
  %Yachain.Block{
    index: 1,
    previous_hash: "C32F3106A2A617A2EB299394AF3DF33F4E3FD9560E5A94F8974F7090E6310812",
    proof: 35293,
    timestamp: #DateTime<2018-04-08 02:16:37.142731Z>,
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
    previous_hash: "95E4EC328CF24C0C96D070FE1FA48A2E52D7E8D4E379858E56649B36785A7202",
    proof: 35089,
    timestamp: #DateTime<2018-04-08 02:18:21.077158Z>,
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

### Node `foo`

Resolve conflicts, resulting in keeping `foo`'s longer chain

```
iex(foo@localhost)12> Controller.resolve_conflicts()
*** Consensus win, keeping current chain ***
[
  %Yachain.Block{
    index: 0,
    previous_hash: "n/a",
    proof: 100,
    timestamp: #DateTime<2018-04-08 02:16:14.055494Z>,
    transactions: []
  },
  %Yachain.Block{
    index: 1,
    previous_hash: "C32F3106A2A617A2EB299394AF3DF33F4E3FD9560E5A94F8974F7090E6310812",
    proof: 35293,
    timestamp: #DateTime<2018-04-08 02:16:37.142731Z>,
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
    previous_hash: "95E4EC328CF24C0C96D070FE1FA48A2E52D7E8D4E379858E56649B36785A7202",
    proof: 35089,
    timestamp: #DateTime<2018-04-08 02:18:21.077158Z>,
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
