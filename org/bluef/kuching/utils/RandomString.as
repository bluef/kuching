package org.bluef.kuching.utils {
	public final class RandomString {
		public static function generateRandomString(newLength:uint  = 64):String {
			var userAlphabet:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
			var alphabet:Array = userAlphabet.split("");
            var alphabetLength:int = alphabet.length;
            var randomLetters:String = "";
            for (var i:uint = 0; i <newLength; i++){
            	randomLetters += alphabet[int(Math.floor(Math.random() * alphabetLength))];
            }
            
            return randomLetters;
    	}
    }
}

