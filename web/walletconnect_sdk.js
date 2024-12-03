const WalletConnect = window.WalletConnect.default;
let connector;

// Connect Wallet
async function connectWallet(callback) {
  try {
    connector = new WalletConnect({
      bridge: "https://bridge.walletconnect.org", // Required bridge URL
      relayProvider: "wss://relay.walletconnect.org",
//      qrcodeModal: true,
        debug: true, // Enable debug mode
    });

    // Check if connection is already established
    if (!connector.connected) {
      await connector.createSession();
    }

    // Listen for connection events
    connector.on("connect", (error, payload) => {
      if (error) {
        throw error;
      }

      // Get provided accounts and chainId
      const { accounts, chainId } = payload.params[0];
      console.log("Connected accounts:", accounts);
      console.log("Connected chainId:", chainId);
    });
    callback(connector.accounts[0]);

//    return connector.accounts[0]; // Return the first connected account
  } catch (error) {
    console.error("Error connecting wallet:", error);
    callback(error);
//    throw error;
  }
}

// Disconnect Wallet
async function disconnectWallet() {
  try {
    if (connector) {
      await connector.killSession();
      console.log("Wallet disconnected");
    }
  } catch (error) {
    console.error("Error disconnecting wallet:", error);
    throw error;
  }
}

window.connectWallet = connectWallet;
window.disconnectWallet = disconnectWallet;
