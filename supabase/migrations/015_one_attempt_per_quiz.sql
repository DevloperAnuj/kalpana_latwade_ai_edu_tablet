-- Phase 13: enforce one quiz attempt per student per material
ALTER TABLE quiz_attempts
ADD CONSTRAINT unique_student_quiz_material UNIQUE (student_id, material_id);
