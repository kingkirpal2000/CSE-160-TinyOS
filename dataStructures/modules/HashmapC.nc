/**
 * ANDES Lab - University of California, Merced
 * This moudle provides a simple hashmap.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * 
 */

generic module HashmapC(typedef t, int n){
   provides interface Hashmap<t>;
}

implementation{
   uint16_t HASH_MAX_SIZE = n;

   typedef struct hashmapEntry{
      uint32_t key;
      t value;
   }hashmapEntry;

   hashmapEntry map[n];
   uint32_t keys[n];
   uint16_t numofVals;

   // Hashing Functions
   uint32_t hash2(uint32_t k){
      return k%13;
   }
   uint32_t hash3(uint32_t k){
      return 1+k%11;
   }

   uint32_t hash(uint32_t k, uint32_t i){
      return (hash2(k)+ i*hash3(k))%HASH_MAX_SIZE;
   }

   command void Hashmap.insert(uint32_t k, t input){
      uint32_t i=0;	uint32_t j=0;

      if(k == 0) return; //Safeguard
      //      dbg("hashmap", "Attempting to place Entry: %hhu\n", k);
      do{
         j=hash(k, i);
         if(map[j].key==0 || map[j].key==k){
            if(map[j].key==0){
               keys[numofVals]=k;
               numofVals++;
            }
            map[j].value=input;
            map[j].key = k;
            //            dbg("hashmap","Entry: %hhu was placed in %hhu\n", k, j);
            return;
         }
         i++;
      }while(i<HASH_MAX_SIZE);
   }

   command void Hashmap.remove(uint32_t k){
      uint32_t i=0;	uint32_t j=0;
      do{
         j=hash(k, i);
         if(map[j].key == k){
            map[j].key=0;
            break;
         }
         i++;
      }while(i<HASH_MAX_SIZE);

      dbg("hashmap", "Removing entry %d\n", k);
      for(i=0; i<numofVals; i++){
         if(keys[i]==k){
            dbg("hashmap", "Key found at %d\n", i);

            for(j=i; j<HASH_MAX_SIZE; j++){
               if(keys[j]==0)break;
               dbg("hashamp", "Moving %d to %d\n", j, j+1);
               dbg("hashamp", "Replacing %d with %d\n", keys[j], keys[j+1]);
               keys[j]=keys[j+1];
            }
            keys[numofVals] = 0;

            numofVals--;
            dbg("hashmap", "Done removing entry\n");
            return;
         }
      }
   }
   command t Hashmap.get(uint32_t k){
      uint32_t i=0;	uint32_t j=0;
      do{
         j=hash(k, i);
         if(map[j].key == k)
            return map[j].value;
         i++;
      }while(i<HASH_MAX_SIZE);	
      return map[0].value;
   }

   command bool Hashmap.contains(uint32_t k){
      uint32_t i=0;	uint32_t j=0;
      do{
         j=hash(k, i);
         if(map[j].key == k)
            return TRUE;
         i++;
      }while(i<HASH_MAX_SIZE);	
      return FALSE;
   }

   command bool Hashmap.isEmpty(){
      if(numofVals==0)
         return TRUE;
      return FALSE;
   }

   command uint32_t* Hashmap.getKeys(){
      return keys;
   }

   command uint16_t Hashmap.size(){
      return numofVals;
   }
}
