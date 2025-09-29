package com.coffee.shop.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QueuePositionResponse {

    private String queueEntryId;
    private Integer position;
    private Integer totalWaiting;
    private Integer estimatedWaitTimeMinutes;
    private String status;
    private String notes;
}

