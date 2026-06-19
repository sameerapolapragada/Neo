import type { MemoryDraft, PetProfileDraft, SnapshotDraft } from '@/types';
import { CAPTION_MAX_LENGTH, NOTES_MAX_LENGTH } from '@/constants/memoryForm';

export type ValidationErrors<T extends object> = Partial<Record<keyof T, string>>;

export function hasErrors<T extends object>(errors: ValidationErrors<T>): boolean {
  return Object.keys(errors).length > 0;
}

export function validatePetProfile(form: PetProfileDraft): ValidationErrors<PetProfileDraft> {
  const errors: ValidationErrors<PetProfileDraft> = {};

  if (!form.name.trim()) {
    errors.name = 'Pet name is required';
  } else if (form.name.trim().length < 2) {
    errors.name = 'Name must be at least 2 characters';
  }

  if (!form.breed.trim()) {
    errors.breed = 'Breed is required';
  }

  if (!form.birthday) {
    errors.birthday = 'Birthday is required';
  }

  if (!form.adoption_date) {
    errors.adoption_date = 'Adoption date is required';
  }

  if (form.weightValue.trim() && !/^\d+(\.\d+)?$/.test(form.weightValue.trim())) {
    errors.weightValue = 'Enter a valid weight';
  }

  return errors;
}

export function validateSnapshotForm(form: SnapshotDraft): ValidationErrors<SnapshotDraft> {
  const errors: ValidationErrors<SnapshotDraft> = {};

  if (!form.favorite_activities.trim()) {
    errors.favorite_activities = 'Tell us about favorite activities';
  } else if (form.favorite_activities.trim().length < 3) {
    errors.favorite_activities = 'Add a bit more detail';
  }

  return errors;
}

export function validateMemoryForm(form: MemoryDraft): ValidationErrors<MemoryDraft> {
  const errors: ValidationErrors<MemoryDraft> = {};

  if (!form.title.trim()) {
    errors.title =
      form.entry_type === 'milestone' ? 'Milestone title is required' : 'Memory title is required';
  } else if (form.title.trim().length < 2) {
    errors.title = 'Title must be at least 2 characters';
  }

  if (!form.description.trim()) {
    errors.description =
      form.entry_type === 'milestone' ? 'Notes are required' : 'Caption is required';
  } else if (form.description.trim().length < 5) {
    errors.description = 'Add a little more about this moment';
  } else {
    const maxLength = form.entry_type === 'milestone' ? NOTES_MAX_LENGTH : CAPTION_MAX_LENGTH;
    if (form.description.trim().length > maxLength) {
      errors.description = `Must be ${maxLength} characters or less`;
    }
  }

  return errors;
}
