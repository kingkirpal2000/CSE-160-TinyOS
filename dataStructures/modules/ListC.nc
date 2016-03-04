/**
 * ANDES Lab - University of California, Merced
 * This class provides a simple list.
 *
 * TODO: Impliment with pointers.
 *
 * @author UCM ANDES Lab
 * @author Alex Beltran
 * @date   2013/09/03
 * 
 */

generic module ListC(typedef t, int n){
	provides interface List<t>;
}

implementation{
	uint16_t MAX_SIZE = n;	

	t container[n];
	uint16_t size = 0;

	command void List.pushback(t input){
		if(size < MAX_SIZE){
			container[size] = input;
			size++;
		}
	}

	command void List.pushfront(t input){
		if(size < MAX_SIZE){
			int32_t i;
			for(i = size-1; i>=0; i--){
				container[i+1] = container[i];
			}

			container[0] = input;
			size++;
		}
	}

	command t List.popback(){
		t returnVal;
	
		returnVal = container[size];
		if(size > 0)size--;
		return returnVal;
	}

	command t List.popfront(){
		t returnVal;
		uint16_t i;
		
		returnVal = container[0];
		if(size>0){
			for(i = 0; i<size-1; i++){
				container[i] = container[i+1];
			}

			size--;
		}	
		
		return returnVal;
	}

	command t List.front(){
		return container[0];
	}

	command t List.back(){
		return container[size];
	}

	command bool List.isEmpty(){
		if(size == 0)
			return TRUE;
		else
			return FALSE;
	}

	command uint16_t List.size(){
		return size;
	}

	command t List.get(uint16_t position){
		return container[position];
	}
}
