import React, { useState } from 'react';
import { Star } from 'lucide-react';
import { Button } from './Button';

export interface RatingStarsProps {
  type?: 'passenger' | 'driver';
  onSubmit?: (rating: number, tags: string[], comment: string) => void;
}

export const RatingStars: React.FC<RatingStarsProps> = ({ type = 'passenger', onSubmit }) => {
  const [rating, setRating] = useState<number>(5);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [comment, setComment] = useState<string>('');

  const passengerTags = ['সময়মতো আগমন', 'নিরাপদ ড্রাইভিং', 'সুন্দর আচরণ', 'পরিস্কার গাড়ি'];
  const driverTags = ['ভালো আচরণ', 'সময়মত উপস্থিতি', 'ভদ্র যাত্রী', 'সহজ পিকআপ'];

  const availableTags = type === 'passenger' ? passengerTags : driverTags;

  const toggleTag = (tag: string) => {
    if (selectedTags.includes(tag)) {
      setSelectedTags(selectedTags.filter((t) => t !== tag));
    } else {
      setSelectedTags([...selectedTags, tag]);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', alignItems: 'center', width: '100%' }}>
      {/* 5-Star Row */}
      <div style={{ display: 'flex', gap: '8px' }}>
        {[1, 2, 3, 4, 5].map((starIndex) => (
          <button
            key={starIndex}
            onClick={() => setRating(starIndex)}
            style={{
              width: '40px',
              height: '40px',
              border: 'none',
              backgroundColor: 'transparent',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              outline: 'none',
            }}
          >
            <Star
              size={28}
              fill={starIndex <= rating ? 'var(--amber-500)' : 'transparent'}
              color={starIndex <= rating ? 'var(--amber-500)' : 'var(--gray-300)'}
            />
          </button>
        ))}
      </div>

      {/* Quick Tag Chips */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', justifyContent: 'center' }}>
        {availableTags.map((tag) => {
          const isSelected = selectedTags.includes(tag);
          return (
            <button
              key={tag}
              onClick={() => toggleTag(tag)}
              style={{
                height: '36px',
                borderRadius: '8px',
                padding: '0 16px',
                border: isSelected ? 'none' : '1.5px solid var(--border-strong)',
                backgroundColor: isSelected ? 'var(--navy-900)' : 'transparent',
                color: isSelected ? '#FFFFFF' : 'var(--text-primary)',
                fontFamily: 'var(--font-ui)',
                fontSize: '14px',
                fontWeight: 500,
                cursor: 'pointer',
                transition: 'all 150ms ease',
              }}
            >
              {tag}
            </button>
          );
        })}
      </div>

      {/* Free-text comment */}
      <textarea
        placeholder="অন্যান্য মতামত (ঐচ্ছিক)..."
        value={comment}
        onChange={(e) => setComment(e.target.value)}
        style={{
          width: '100%',
          height: '72px',
          borderRadius: '12px',
          border: '1px solid var(--border-strong)',
          padding: '12px',
          fontFamily: 'var(--font-ui)',
          fontSize: '14px',
          outline: 'none',
          resize: 'none',
        }}
      />

      <Button fullWidth onClick={() => onSubmit && onSubmit(rating, selectedTags, comment)}>
        রেটিং জমা দিন
      </Button>
    </div>
  );
};
