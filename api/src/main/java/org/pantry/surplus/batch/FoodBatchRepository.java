package org.pantry.surplus.batch;

import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FoodBatchRepository extends JpaRepository<FoodBatch, Long> {

    @Query("""
            select b from FoodBatch b
            where (:search = '' or lower(b.itemName) like lower(concat('%', :search, '%')))
              and b.expiryDate >= :fromDate
            order by b.expiryDate, b.itemName
            """)
    List<FoodBatch> search(@Param("search") String search, @Param("fromDate") LocalDate fromDate);
}
