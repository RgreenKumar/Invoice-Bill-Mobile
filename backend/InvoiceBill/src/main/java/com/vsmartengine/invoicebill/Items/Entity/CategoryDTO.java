package com.vsmartengine.invoicebill.Items.Entity;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryDTO {

    private Long id;

   
    private String name;
    
    private Long itemCount;
  
}