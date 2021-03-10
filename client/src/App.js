import React, { Component } from "react";
import ClaimerContract from "./contracts/Claimer.json";

import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  state = { web3: null, account: null };
  constructor(){
    super();
    this.signParams = this.signParams.bind(this);
    this.claim = this.claim.bind(this);
  }

  componentDidMount = async () => {
    try {
      const web3 = await getWeb3();
      const [account] = await web3.eth.getAccounts();
      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = ClaimerContract.networks[networkId];
      const claimContract = new web3.eth.Contract(
        ClaimerContract.abi,
        '0x3F8AfbE953C74f6EB0aBfCc0ebBbb73ba514B206',//TODO put Claimer contract address here
      );


      this.setState({ web3, account, claimContract });
    } catch (error) {
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  async claim(){
    const element = document.getElementById("code");
    const code = element.value.trim();
    const [wearableId, signature, nonceCount] = code.split(";");
    const {claimContract, account} = this.state;
    const res = await claimContract.methods
      .claim(wearableId, nonceCount, signature)
      .send({from:account});
  }

  async signParams(){
    const form = document.getElementById("form");
    const [wearableId, winnerAddress, nonceCount] = Array.from(form.elements[0].elements).map(el=>el.value);
    var msgParams = [
      {
          type: 'string',
          name: 'wearableId',
          value: wearableId
      },
      {
          type: 'uint8',
          name:'nonceCount',
          value: Number(nonceCount)
      },
      {
        type:'address',
        name:'winnerAddress',
        value:winnerAddress
      }
  ];
    var from = this.state.account;
    var params = [msgParams, from];
    var method = 'eth_signTypedData';
   this.state.web3.currentProvider.sendAsync({
        method,
        params,
        from,
    }, (err, response)=>{
      console.log("res",response.result);
      this.setState((state, props) => {      
        return {...state, signature:response.result, code:`${wearableId};${response.result};${nonceCount}`};
      });
    });
   
   /*  this.setState((state, props) => {
      
      return {...state, wearableId, winnerAddress, nonceCount:Number(nonceCount)};
    }); */

  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div >
        <section className="section admin">
            <h2>Admin</h2>
            <form action="#" id="form"><fieldset>
                Signing with {this.state.account}<br/><br/>
                <label>wearableId</label><br/>
                <input type="text" defaultValue={"mf_frogfins"} /><br/><br/>
              
                <label>winner address</label><br/>
                <input type="text" defaultValue={"0x908486487568d825B6cbfF2F9b5360a6c7E05BBB"} /><br/><br/>

                <label>nonce count</label><br/>
                <input type="number" defaultValue={0} /><br/><br/>

                <input type="button" onClick={this.signParams} value="SIGN" />  
            </fieldset></form>
            <div>
              <div>Code:</div>
              <textarea readOnly={true} style={{width:400, height:60}} value={this.state.code}></textarea>
            </div>
        </section>
        <br/><br/>
        <section>
          <h2>Claim your wearable</h2>
          <h3>Introduce your claiming code here:</h3>
          <textarea id="code" style={{width:400, height:100}}></textarea>
          <br/>
          <input type="button" value="CLAIM" onClick={this.claim} />
        </section>
      </div>
    );
  }
}

export default App;
