// Initialize MetaMask SDK
if (typeof window.ethereum !== "undefined") {
  console.log("MetaMask is installed!");

  // Request account access
  async function connectWallet(callback) {
    try {
      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
      console.log("MetaMask " + accounts[0]);
      callback(accounts[0]);
    } catch (error) {
      console.error("Error connecting to wallet:", error);
      callback(error);
    }
  }

  // Get current account
  async function getCurrentAccount() {
    try {
      const accounts = await window.ethereum.request({ method: "eth_accounts" });
      return accounts[0] || null; // Return null if no accounts
    } catch (error) {
      console.error("Error fetching account:", error);
      throw error;
    }
  }

  // Send transaction
  async function sendTransaction(to, value) {
    try {
      const transactionParameters = {
        to: to,
        value: value, // Value in Wei
      };
      const txHash = await window.ethereum.request({
        method: "eth_sendTransaction",
        params: [transactionParameters],
      });
      return txHash;
    } catch (error) {
      console.error("Error sending transaction:", error);
      throw error;
    }
  }

  // Expose functions to Flutter
  window.connectWallet = connectWallet;
  window.getCurrentAccount = getCurrentAccount;
  window.sendTransaction = sendTransaction;
} else {
  console.error("MetaMask is not installed.");
}
