/*
	AS3 Interface for krpano
	--
	krpano.com
*/

package
{
	public class krpano_as3_interface
	{
		public static var instance:krpano_as3_interface = null;


		public function krpano_as3_interface()
		{
		}
	

		public static function getInstance():krpano_as3_interface
		{
			if (instance == null)
				instance = new krpano_as3_interface();

			return instance;
		}
		

		public var set      : Function = null;
		public var get      : Function = null;
		public var call     : Function = null;
		public var callback : Function = null;		// krpano version 1.0.5 and greater
	}
}
