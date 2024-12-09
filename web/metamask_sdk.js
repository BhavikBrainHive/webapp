alert("Please open this link in an external browser to complete login.");
const MMSDK = new MetaMaskSDK.MetaMaskSDK({
        dappMetadata: {
          name: "Flutter Web Dapp",
        },
        infuraAPIKey: "1234567890", // Replace with your Infura API key
      });

      // Expose MetaMask connection methods to Flutter
      async function connectMetaMask(callback) {
        try {
          const accounts = await MMSDK.connect();
          console.log("Connected accounts:", accounts);
          callback(accounts[0]);
//          return accounts; // Return connected accounts
        } catch (error) {
          console.error("Error connecting MetaMask:", error);
          callback(error);
//          throw error; // Rethrow the error for Flutter to handle
        }
      }

      async function disconnectMetaMask() {
        try {
          await MMSDK.disconnect();
          console.log("Disconnected MetaMask");
          return true;
        } catch (error) {
          console.error("Error disconnecting MetaMask:", error);
          throw error;
        }
      }

      window.connectMetaMask = connectMetaMask;
      window.disconnectMetaMask = disconnectMetaMask;